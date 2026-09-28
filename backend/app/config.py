import os
from typing import Optional
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    SQLITE_DB_PATH: str = os.path.abspath(
        os.path.join(os.path.dirname(os.path.dirname(__file__)), "goalsync.db")
    )
    DATABASE_NAME: str = "goalsync.db"
    DATABASE_URL: Optional[str] = None
    JWT_SECRET: str = "super-secret-key-change-this-in-production-32-bytes"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    GOALSYNC_ALLOW_DEV_USER_MAPPING: bool = False
    MONGODB_URI: str = ""

    # Subscription & Business Configuration (Prices in INR)
    PLAN_PREMIUM_MONTHLY_PRICE: float = 99.0
    PLAN_PREMIUM_ANNUAL_PRICE: float = 990.0  # 2 months free
    PLAN_STUDENT_MONTHLY_PRICE: float = 49.0
    PLAN_STUDENT_ANNUAL_PRICE: float = 490.0
    PLAN_FAMILY_MONTHLY_PRICE: float = 199.0
    PLAN_FAMILY_ANNUAL_PRICE: float = 1990.0
    FAMILY_MAX_MEMBERS: int = 5
    TRIAL_DURATION_DAYS: int = 14

    # Student Eligibility & Trial Configuration
    STUDENT_TRIAL_DAYS: int = 30
    STUDENT_ALLOWED_DOMAINS: list[str] = [".edu", ".ac.in", ".edu.in", "university.edu", "college.edu"]
    STUDENT_ALLOW_SELF_DECLARED_DEMO: bool = True

    # Tax Rate (Default 18% GST - VERIFY WITH ACCOUNTANT)
    TAX_RATE: float = 0.18

    # Payment Gateway Configuration
    PAYMENT_GATEWAY: str = "demo"  # "demo", "razorpay", "cashfree"
    PAYMENT_WEBHOOK_SECRET: str = "demo_webhook_secret_do_not_use_in_prod"
    RAZORPAY_KEY_ID: str = "rzp_test_pennora_demo_key"
    RAZORPAY_KEY_SECRET: str = "rzp_test_secret_demo"

    model_config = SettingsConfigDict(
        env_file=(
            os.path.join(os.path.dirname(os.path.dirname(__file__)), ".env"),
            os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), ".env"),
        ),
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()
