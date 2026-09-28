"""Phase 6: Financial Health & Growth Report Routes.

Provides REST endpoints for purchasing, generating, listing,
and securely downloading PDF reports with strict ownership isolation.
"""

import base64
import json
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status, Response
from pydantic import BaseModel, Field

from app.database import get_collection
from app.dependencies import get_current_user, require_premium
from app.services.report_service import (
    purchase_report,
    generate_and_store_report,
)

router = APIRouter(prefix="/api/reports", tags=["Financial Reports"])


class PurchaseReportRequest(BaseModel):
    is_demo: bool = Field(default=True)


def _serialize_report(doc: dict) -> dict:
    """Helper to return report metadata without transmitting the large base64 PDF string."""
    summary_data = None
    if doc.get("summaryJson"):
        try:
            summary_data = json.loads(doc["summaryJson"])
        except Exception:
            summary_data = doc["summaryJson"]

    return {
        "_id": str(doc["_id"]),
        "userId": str(doc["userId"]),
        "reportType": doc.get("reportType", "financial_health_growth"),
        "status": doc.get("status", "pending"),
        "hasPdf": bool(doc.get("pdfBytes")),
        "purchaseId": doc.get("purchaseId"),
        "isDemo": doc.get("isDemo", True),
        "summary": summary_data,
        "generatedAt": doc.get("generatedAt").isoformat() if hasattr(doc.get("generatedAt"), "isoformat") else doc.get("generatedAt"),
        "asOfDate": doc.get("asOfDate").isoformat() if hasattr(doc.get("asOfDate"), "isoformat") else doc.get("asOfDate"),
        "createdAt": doc.get("createdAt").isoformat() if hasattr(doc.get("createdAt"), "isoformat") else doc.get("createdAt"),
    }


@router.post("/purchase")
def purchase_financial_report(
    payload: PurchaseReportRequest = PurchaseReportRequest(),
    current_user: dict = Depends(require_premium),
):
    """Purchases a comprehensive financial health and growth report.

    Requires an active Premium, Student, or Family subscription (returns HTTP 403 for free users).
    """
    user_id = str(current_user["_id"])
    try:
        report_doc = purchase_report(user_id=user_id, is_demo=payload.is_demo)
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

    return {
        "status": "success",
        "message": "Report purchased successfully. Ready for generation.",
        "report": _serialize_report(report_doc),
    }


@router.post("/{report_id}/generate")
def generate_report(
    report_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Triggers generation of the PDF report using user's real financial data.

    Enforces strict ownership: users can only generate their own reports.
    """
    user_id = str(current_user["_id"])
    reports_coll = get_collection("financial_reports")
    report = reports_coll.find_one({"_id": str(report_id)})

    if not report:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report not found.")

    if str(report["userId"]) != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: You cannot generate a report belonging to another user.",
        )

    try:
        updated = generate_and_store_report(user_id=user_id, report_id=report_id)
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

    return {
        "status": "success",
        "message": "Report generated successfully.",
        "report": _serialize_report(updated),
    }


@router.get("/")
def list_reports(
    current_user: dict = Depends(get_current_user),
):
    """Lists all financial reports belonging to the authenticated user."""
    user_id = str(current_user["_id"])
    reports_coll = get_collection("financial_reports")
    reports = list(reports_coll.find({"userId": user_id}).sort("createdAt", -1))
    return {
        "status": "success",
        "count": len(reports),
        "reports": [_serialize_report(r) for r in reports],
    }


@router.get("/{report_id}")
def get_report_metadata(
    report_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Retrieves metadata of a specific report. Enforces user ownership."""
    user_id = str(current_user["_id"])
    reports_coll = get_collection("financial_reports")
    report = reports_coll.find_one({"_id": str(report_id)})

    if not report:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report not found.")

    if str(report["userId"]) != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: You cannot view reports belonging to another user.",
        )

    return {
        "status": "success",
        "report": _serialize_report(report),
    }


@router.get("/{report_id}/download")
def download_report_pdf(
    report_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Downloads the generated PDF report.

    Enforces ownership isolation and checks completion status.
    """
    user_id = str(current_user["_id"])
    reports_coll = get_collection("financial_reports")
    report = reports_coll.find_one({"_id": str(report_id)})

    if not report:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report not found.")

    if str(report["userId"]) != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: You cannot download reports belonging to another user.",
        )

    if report.get("status") != "completed" or not report.get("pdfBytes"):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Report has not finished generating or generation failed.",
        )

    try:
        raw_pdf = base64.b64decode(report["pdfBytes"])
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Could not decode stored PDF file.",
        )

    return Response(
        content=raw_pdf,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f'attachment; filename="Pennora_Report_{report_id}.pdf"',
            "Content-Type": "application/pdf",
        },
    )
