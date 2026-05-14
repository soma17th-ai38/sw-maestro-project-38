from __future__ import annotations

import re
import sqlite3
import sys
from typing import Optional

from graph.db_path import resolve_db_path

_INTEL_I_RE = re.compile(r"\bi([3579])-?(\d{3,5}[a-z]?)\b")
_ULTRA_RE = re.compile(r"\bultra\s*[- ]?\s*([579])(?:\s*-?\s*(\d{3,5}[a-z]?))?\b")
_RYZEN_RE = re.compile(r"\bryzen\s+([3579])\s+(\d{4,5}[a-z]+)\b")
_APPLE_M_RE = re.compile(r"\bm([1-4])\b")


def tokens_for_cpu(cpu_value: str) -> frozenset[str]:
    if not cpu_value:
        return frozenset()

    s = cpu_value.lower()
    tokens: set[str] = set()

    if "intel" in s:
        tokens.update({"intel", "인텔"})
    if "amd" in s or "ryzen" in s:
        tokens.add("amd")
    if "ryzen" in s:
        tokens.update({"ryzen", "라이젠"})
    if "apple" in s:
        tokens.update({"apple", "애플", "맥"})
    if "core" in s:
        tokens.update({"core", "코어"})

    ultra_match = _ULTRA_RE.search(s)
    if ultra_match:
        digit = ultra_match.group(1)
        tokens.update({"ultra", "울트라", f"ultra {digit}", f"울트라 {digit}"})
        model = ultra_match.group(2)
        if model:
            tokens.add(model)

    intel_i_match = _INTEL_I_RE.search(s)
    if intel_i_match:
        digit = intel_i_match.group(1)
        model = intel_i_match.group(2)
        tokens.update({f"i{digit}", f"인텔 i{digit}", f"코어 i{digit}"})
        tokens.add(f"i{digit}-{model}")
        tokens.add(model)

    ryzen_match = _RYZEN_RE.search(s)
    if ryzen_match:
        digit = ryzen_match.group(1)
        model = ryzen_match.group(2)
        tokens.update({f"ryzen {digit}", f"라이젠 {digit}"})
        tokens.add(model)

    apple_m_match = _APPLE_M_RE.search(s)
    if apple_m_match:
        digit = apple_m_match.group(1)
        m_token = f"m{digit}"
        tokens.add(m_token)
        if "pro" in s:
            tokens.update({f"{m_token} pro", f"{m_token} 프로", "pro", "프로"})
        if "max" in s:
            tokens.update({f"{m_token} max", f"{m_token} 맥스", "max", "맥스"})
        if "ultra" in s:
            tokens.update({f"{m_token} ultra", f"{m_token} 울트라"})

    return frozenset(tokens)


def build_cpu_index(conn: sqlite3.Connection) -> dict[str, frozenset[str]]:
    accumulator: dict[str, set[str]] = {}
    cursor = conn.execute("SELECT DISTINCT cpu FROM laptops WHERE cpu IS NOT NULL")
    for (cpu_value,) in cursor.fetchall():
        for token in tokens_for_cpu(cpu_value):
            accumulator.setdefault(token, set()).add(cpu_value)
    return {key: frozenset(values) for key, values in accumulator.items()}


def tokenize_and_lookup(
    index: dict[str, frozenset[str]], user_input: str
) -> list[str]:
    if not user_input:
        return []

    raw = user_input.strip().lower().split()
    if not raw:
        return []

    matched_sets: list[frozenset[str]] = []
    i = 0
    n = len(raw)
    while i < n:
        if i + 1 < n:
            bigram = f"{raw[i]} {raw[i + 1]}"
            if bigram in index:
                matched_sets.append(index[bigram])
                i += 2
                continue
        if raw[i] in index:
            matched_sets.append(index[raw[i]])
        i += 1

    if not matched_sets:
        return []

    result = matched_sets[0]
    for token_set in matched_sets[1:]:
        result = result & token_set
        if not result:
            break

    return sorted(result)


_INDEX_CACHE: Optional[dict[str, frozenset[str]]] = None


def get_cpu_index() -> dict[str, frozenset[str]]:
    global _INDEX_CACHE
    if _INDEX_CACHE is not None:
        return _INDEX_CACHE

    db_path = resolve_db_path()
    try:
        conn = sqlite3.connect(db_path)
        try:
            index = build_cpu_index(conn)
        finally:
            conn.close()
    except sqlite3.Error as exc:
        sys.stderr.write(
            f"[cpu_index] WARN: failed to read CPU rows from {db_path}: {exc}. "
            "Returning empty index; will retry on next call.\n"
        )
        return {}

    if not index:
        sys.stderr.write(
            f"[cpu_index] WARN: built index is empty (no CPU rows in {db_path}). "
            "Returning empty index; will retry on next call.\n"
        )
        return {}

    _INDEX_CACHE = index
    return _INDEX_CACHE


def reset_cpu_index() -> None:
    global _INDEX_CACHE
    _INDEX_CACHE = None
