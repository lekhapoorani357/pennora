from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from app.database import get_database, init_db
from app.routes import (
    auth,
    users,
    financial_profiles,
    goals,
    transactions,
    pipeline,
    insights,
    investments,
    subscriptions,
    ads,
    partners,
    analytics,
    admin,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize SQLite database and tables on startup
    try:
        init_db()
        print("✔ SQLite database and tables initialized successfully.")
    except Exception as e:
        print(f"⚠ Warning: Database initialization error: {e}")
    yield


app = FastAPI(
    title="Pennora Backend API",
    description="FastAPI REST API connected to local SQLite for Pennora financial intelligence platform.",
    version="2.0.0",
    lifespan=lifespan,
)

# CORS middleware for Flutter Web & Mobile development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(financial_profiles.router)
app.include_router(financial_profiles.profile_router)
app.include_router(goals.router)
app.include_router(transactions.router)
app.include_router(pipeline.router)
app.include_router(insights.router)
app.include_router(investments.router)
app.include_router(subscriptions.router)
app.include_router(ads.router)
app.include_router(partners.router)
app.include_router(analytics.router)
app.include_router(admin.router)


@app.get("/health", tags=["Health"])
def health_check():
    """Basic health check endpoint."""
    return {"status": "ok"}


@app.get("/health/db", tags=["Health"])
def database_health_check():
    """Pings database and confirms database connectivity and engine type."""
    try:
        from app.database import get_engine
        engine = get_engine()
        dialect_name = engine.dialect.name
        db_type = "PostgreSQL" if "postgres" in dialect_name else dialect_name.upper()
        db = get_database()
        ping_res = db.command("ping")
        return {
            "status": "ok",
            "database_type": db_type,
            "database": db.name,
            "dialect": dialect_name,
            "ping": ping_res,
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Database connection failure: {str(e)}",
        )

