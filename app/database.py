# app/database.py
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.pool import StaticPool

# Read DB URL from env (tests set this to sqlite:///:memory:)
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./tasks.db")

# Default engine args
engine_args = {"echo": False}

# If using SQLite, set connect_args. For in-memory SQLite we also use StaticPool
# so the same connection (and thus the same in-memory DB) is reused across sessions.
if DATABASE_URL.startswith("sqlite"):
    connect_args = {"check_same_thread": False}

    # Detect the in-memory URL variants and use StaticPool so the DB is preserved across connections
    if DATABASE_URL in ("sqlite:///:memory:", "sqlite://"):
        engine = create_engine(
            DATABASE_URL,
            connect_args=connect_args,
            poolclass=StaticPool,
            **engine_args,
        )
    else:
        engine = create_engine(
            DATABASE_URL,
            connect_args=connect_args,
            **engine_args,
        )
else:
    # Non-sqlite DBs (Postgres, MySQL...) use default behaviour
    engine = create_engine(DATABASE_URL, **engine_args)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()
