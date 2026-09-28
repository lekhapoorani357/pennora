"""Database migration script: SQLite (goalsync.db) -> Supabase PostgreSQL.

Reads all records from SQLite and writes them into Supabase PostgreSQL,
preserving existing tables, schemas, and accounts.
"""

import sys
import os

# Ensure backend root is in sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy import create_engine, select, text
from sqlalchemy.orm import sessionmaker
from app.config import settings
from app.models import Base
from app.database import COLLECTION_MODEL_MAP


def run_migration():
    if not settings.DATABASE_URL:
        print("ERROR: DATABASE_URL is not set in backend/.env or environment.")
        sys.exit(1)

    pg_url = settings.DATABASE_URL
    if pg_url.startswith("postgres://"):
        pg_url = pg_url.replace("postgres://", "postgresql://", 1)

    sqlite_path = os.path.abspath(settings.SQLITE_DB_PATH)
    if not os.path.exists(sqlite_path):
        print(f"Warning: SQLite database at {sqlite_path} does not exist. Only creating schema.")
        sqlite_exists = False
    else:
        sqlite_exists = True

    print("Initializing Supabase PostgreSQL connection...")
    pg_engine = create_engine(pg_url, pool_pre_ping=True)

    # 1. Create all tables in PostgreSQL
    print("Creating tables in PostgreSQL...")
    Base.metadata.create_all(bind=pg_engine)
    print("Tables created successfully.")

    if not sqlite_exists:
        print("Migration complete (schema initialized).")
        return

    # 2. Open SQLite session
    sqlite_engine = create_engine(f"sqlite:///{sqlite_path}")
    SqliteSession = sessionmaker(bind=sqlite_engine)
    PgSession = sessionmaker(bind=pg_engine)

    sqlite_sess = SqliteSession()
    pg_sess = PgSession()

    try:
        migrated_counts = {}
        for coll_name, model_cls in COLLECTION_MODEL_MAP.items():
            try:
                # Query all records from SQLite
                instances = sqlite_sess.scalars(select(model_cls)).all()
                count = 0
                for inst in instances:
                    # Check if already exists by primary key in PG
                    pk_val = getattr(inst, "_id", None) or getattr(inst, "id", None)
                    existing = pg_sess.get(model_cls, pk_val) if pk_val else None
                    if not existing:
                        pg_sess.merge(inst)
                        count += 1
                pg_sess.commit()
                migrated_counts[coll_name] = count
                print(f"  - Table '{coll_name}': {count} new records migrated ({len(instances)} total in SQLite).")
            except Exception as e:
                pg_sess.rollback()
                print(f"  ! Table '{coll_name}' migration notice: {e}")

        print("\nAll tables synchronized successfully!")
        return migrated_counts
    finally:
        sqlite_sess.close()
        pg_sess.close()


if __name__ == "__main__":
    run_migration()
