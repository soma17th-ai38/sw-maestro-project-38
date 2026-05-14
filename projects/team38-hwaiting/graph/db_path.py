from __future__ import annotations

import os
from pathlib import Path

_PROJECT_ROOT = Path(__file__).resolve().parent.parent


def resolve_db_path() -> str:
    raw = os.getenv("DB_PATH", "db/laptops.db")
    p = Path(raw)
    if not p.is_absolute():
        p = _PROJECT_ROOT / p
    return str(p)
