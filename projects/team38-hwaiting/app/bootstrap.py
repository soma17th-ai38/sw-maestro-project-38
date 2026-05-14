"""Runtime bootstrap helpers for local and Streamlit Cloud execution."""
from __future__ import annotations

import os
import sqlite3
from pathlib import Path

import streamlit as st

_PROJECT_ROOT = Path(__file__).resolve().parent.parent
_RUNTIME_ENV_KEYS = (
    "UPSTAGE_API_KEY",
    "UPSTAGE_MODEL_PRIMARY",
    "UPSTAGE_MODEL_FAST",
    "DB_PATH",
    "LOG_LEVEL",
)


def _sync_streamlit_secrets_to_env() -> None:
    """Keep existing os.getenv-based code working in Streamlit Cloud."""
    for key in _RUNTIME_ENV_KEYS:
        if key in os.environ:
            continue
        try:
            value = st.secrets[key]
        except Exception:  # noqa: BLE001
            continue
        os.environ[key] = str(value)


def _resolve_db_path() -> Path:
    raw = os.getenv("DB_PATH", "db/laptops.db")
    path = Path(raw)
    if not path.is_absolute():
        path = _PROJECT_ROOT / path
    os.environ["DB_PATH"] = str(path)
    return path


def _ensure_seed_db(db_path: Path) -> None:
    if db_path.exists():
        return

    schema_path = _PROJECT_ROOT / "db" / "schema.sql"
    seed_path = _PROJECT_ROOT / "db" / "seed_dummy.sql"
    db_path.parent.mkdir(parents=True, exist_ok=True)

    with sqlite3.connect(db_path) as conn:
        conn.executescript(schema_path.read_text(encoding="utf-8"))
        conn.executescript(seed_path.read_text(encoding="utf-8"))


def bootstrap_runtime() -> None:
    _sync_streamlit_secrets_to_env()
    db_path = _resolve_db_path()
    _ensure_seed_db(db_path)
