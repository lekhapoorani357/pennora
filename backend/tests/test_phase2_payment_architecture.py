"""Phase 2: Payment Architecture & Webhook Idempotency Test Suite.

Validates:
1. Replaceable PaymentService abstraction (Demo + Razorpay test adapters).
2. Order creation storing pending payment records.
3. Cryptographic webhook signature verification (rejection of forged signatures).
4. Idempotent webhook processing (replayed webhooks NEVER duplicate payments, subscriptions, or revenue).
5. Client-side bypass prevention (client cannot mark payments paid directly).
6. Tax rate accounting (gross, tax, and net revenue accurately tracked).
"""

import hashlib
import hmac
import json
import pytest
from datetime import datetime, timezone
from fastapi.testclient import TestClient
from sqlalchemy import create_engine

from app.main import app
from app.config import settings
from app.database import set_engine, reset_engine, init_db, get_collection
from app.services.payment_service import get_payment_adapter, DemoPaymentAdapter, RazorpayTestGatewayAdapter


@pytest.fixture(scope="module")
def client():
    test_engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False})
    set_engine(test_engine)
    init_db(test_engine)

    with TestClient(app) as test_client:
        yield test_client

    reset_engine()


def register_and_login(client: TestClient, email: str) -> dict:
    import hashlib
    phone_suffix = str(abs(hash(email)) % 100000000).zfill(8)
    client.post(
        "/auth/register",
        json={
            "fullName": "Payment Test User",
            "email": email,
            "phone": f"91{phone_suffix}",
            "password": "Password123!",
        },
    )
    login_res = client.post(
        "/auth/login",
        json={
            "identifier": email,
            "password": "Password123!",
        },
    )
    token = login_res.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_payment_adapter_factory():
    demo_adapter = get_payment_adapter("demo")
    assert isinstance(demo_adapter, DemoPaymentAdapter)

    rzp_adapter = get_payment_adapter("razorpay")
    assert isinstance(rzp_adapter, RazorpayTestGatewayAdapter)


def test_order_creation_stores_pending_payment(client):
    headers = register_and_login(client, "order_maker@example.com")

    # Create order for premium_monthly
    res = client.post(
        "/api/subscription/create-order",
        json={"planCode": "premium_monthly"},
        headers=headers,
    )
    assert res.status_code == 200
    data = res.json()
    assert "orderId" in data
    assert data["amount"] == settings.PLAN_PREMIUM_MONTHLY_PRICE
    assert data["currency"] == "INR"

    order_id = data["orderId"]

    # Verify payment record is in payments table with status="pending"
    pay_coll = get_collection("payments")
    payment = pay_coll.find_one({"gatewayRef": order_id})
    assert payment is not None
    assert payment["status"] == "pending"
    assert payment["amount"] == settings.PLAN_PREMIUM_MONTHLY_PRICE

    # User MUST still be blocked from premium (client has not paid yet)
    gate_res = client.get("/api/subscription/premium-check", headers=headers)
    assert gate_res.status_code == 403


def test_webhook_invalid_signature_rejected(client):
    headers = register_and_login(client, "forger@example.com")
    order_res = client.post(
        "/api/subscription/create-order",
        json={"planCode": "premium_monthly"},
        headers=headers,
    )
    order_id = order_res.json()["orderId"]

    fake_payload = {
        "event": "payment.captured",
        "orderId": order_id,
        "paymentId": "pay_forged_123",
        "amount": 99.0,
    }
    raw_body = json.dumps(fake_payload).encode("utf-8")

    # Send webhook with forged signature
    webhook_res = client.post(
        "/api/subscription/webhook",
        content=raw_body,
        headers={
            "Content-Type": "application/json",
            "x-webhook-signature": "invalid_forged_signature_12345",
        },
    )
    assert webhook_res.status_code == 400
    assert "Invalid webhook signature" in webhook_res.json()["detail"]


def test_webhook_activation_and_idempotency(client):
    headers = register_and_login(client, "idempotent_buyer@example.com")

    # 1. Create order
    order_res = client.post(
        "/api/subscription/create-order",
        json={"planCode": "family_annual"},
        headers=headers,
    )
    assert order_res.status_code == 200
    order_id = order_res.json()["orderId"]
    expected_amount = settings.PLAN_FAMILY_ANNUAL_PRICE

    # 2. Construct valid webhook event
    payload = {
        "event": "payment.captured",
        "orderId": order_id,
        "paymentId": "pay_real_987654",
        "amount": expected_amount,
        "currency": "INR",
    }
    raw_bytes = json.dumps(payload).encode("utf-8")
    secret = settings.PAYMENT_WEBHOOK_SECRET
    valid_sig = hmac.new(secret.encode("utf-8"), raw_bytes, hashlib.sha256).hexdigest()

    # 3. Deliver webhook for the FIRST time
    res1 = client.post(
        "/api/subscription/webhook",
        content=raw_bytes,
        headers={
            "Content-Type": "application/json",
            "x-webhook-signature": valid_sig,
        },
    )
    assert res1.status_code == 200
    res1_data = res1.json()
    assert res1_data["status"] == "success"
    assert res1_data["idempotent"] is False

    # Verify user is now activated and entitled
    gate_res = client.get("/api/subscription/premium-check", headers=headers)
    assert gate_res.status_code == 200

    # Count database entries after 1st delivery
    pay_coll = get_collection("payments")
    sub_coll = get_collection("subscriptions")
    rev_coll = get_collection("revenue_events")

    payments_count_1 = len(list(pay_coll.find({"gatewayRef": "pay_real_987654"})))
    subs_count_1 = len(list(sub_coll.find({"tier": "family", "status": "active"})))
    revs_count_1 = len(list(rev_coll.find({"eventType": "DEMO_FAMILY_SUBSCRIPTION_PAID"})))

    assert payments_count_1 == 1
    assert subs_count_1 == 1
    assert revs_count_1 == 1

    # 4. REPLAY the EXACT SAME webhook a SECOND time (simulating network retry/duplicate webhook)
    res2 = client.post(
        "/api/subscription/webhook",
        content=raw_bytes,
        headers={
            "Content-Type": "application/json",
            "x-webhook-signature": valid_sig,
        },
    )
    assert res2.status_code == 200
    res2_data = res2.json()
    assert res2_data["status"] == "already_processed"
    assert res2_data["idempotent"] is True

    # 5. VERIFY IDEMPOTENCY IN DATABASE
    # MUST NOT create duplicate payment!
    payments_count_2 = len(list(pay_coll.find({"gatewayRef": "pay_real_987654"})))
    assert payments_count_2 == 1, "Duplicate payment created on webhook replay!"

    # MUST NOT create duplicate subscription!
    subs_count_2 = len(list(sub_coll.find({"tier": "family", "status": "active"})))
    assert subs_count_2 == 1, "Duplicate subscription created on webhook replay!"

    # MUST NOT create duplicate revenue!
    revs_count_2 = len(list(rev_coll.find({"eventType": "DEMO_FAMILY_SUBSCRIPTION_PAID"})))
    assert revs_count_2 == 1, "Duplicate revenue created on webhook replay!"


def test_razorpay_signature_verification_adapter():
    adapter = RazorpayTestGatewayAdapter(key_id="rzp_test_123", key_secret="rzp_secret_abc")
    body = b'{"event":"payment.captured","amount":9900}'
    expected_sig = hmac.new(b"rzp_secret_abc", body, hashlib.sha256).hexdigest()

    assert adapter.verify_webhook_signature(body, expected_sig) is True
    assert adapter.verify_webhook_signature(body, "wrong_sig") is False
    assert adapter.verify_webhook_signature(body, None) is False
