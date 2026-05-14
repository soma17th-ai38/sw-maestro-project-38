from __future__ import annotations

import sqlite3

import pytest

from pathlib import Path

from graph import cpu_index, nodes
from graph.cpu_index import (
    build_cpu_index,
    reset_cpu_index,
    tokenize_and_lookup,
    tokens_for_cpu,
)
from graph.db_path import resolve_db_path


SEED_CPUS = [
    "Intel Core Ultra 5-125H",
    "Intel Core i5-1335U",
    "Apple M3",
    "Apple M3 Pro",
    "AMD Ryzen 9 7940HX",
    "Intel Core i5-13420H",
    "Intel Core i7-1355U",
    "Intel Core Ultra 7-155H",
    "AMD Ryzen 7 7840U",
]


@pytest.fixture
def seeded_index() -> dict[str, frozenset[str]]:
    conn = sqlite3.connect(":memory:")
    conn.execute("CREATE TABLE laptops (cpu TEXT NOT NULL)")
    conn.executemany(
        "INSERT INTO laptops (cpu) VALUES (?)", [(c,) for c in SEED_CPUS]
    )
    conn.commit()
    try:
        return build_cpu_index(conn)
    finally:
        conn.close()


class TestTokensForCpu:
    def test_intel_core_i5_with_model(self):
        tokens = tokens_for_cpu("Intel Core i5-1335U")
        assert {"intel", "인텔", "core", "코어", "i5", "인텔 i5", "코어 i5"} <= tokens
        assert "i5-1335u" in tokens
        assert "1335u" in tokens

    def test_intel_core_i7(self):
        tokens = tokens_for_cpu("Intel Core i7-1355U")
        assert {"intel", "인텔", "i7", "인텔 i7", "i7-1355u"} <= tokens

    def test_intel_core_ultra_5(self):
        tokens = tokens_for_cpu("Intel Core Ultra 5-125H")
        assert {"intel", "인텔", "ultra", "울트라", "ultra 5", "울트라 5"} <= tokens
        assert "125h" in tokens
        assert "i5" not in tokens

    def test_intel_core_ultra_7(self):
        tokens = tokens_for_cpu("Intel Core Ultra 7-155H")
        assert {"ultra 7", "울트라 7", "155h"} <= tokens

    def test_amd_ryzen_7_with_model(self):
        tokens = tokens_for_cpu("AMD Ryzen 7 7840U")
        assert {"amd", "ryzen", "라이젠", "ryzen 7", "라이젠 7"} <= tokens
        assert "7840u" in tokens

    def test_amd_ryzen_9_hx_model(self):
        tokens = tokens_for_cpu("AMD Ryzen 9 7940HX")
        assert {"amd", "ryzen 9", "라이젠 9"} <= tokens
        assert "7940hx" in tokens

    def test_apple_m3_plain(self):
        tokens = tokens_for_cpu("Apple M3")
        assert {"apple", "애플", "맥", "m3"} <= tokens
        assert "pro" not in tokens
        assert "프로" not in tokens

    def test_apple_m3_pro(self):
        tokens = tokens_for_cpu("Apple M3 Pro")
        assert {"apple", "m3", "m3 pro", "m3 프로", "pro", "프로"} <= tokens

    def test_empty_input(self):
        assert tokens_for_cpu("") == frozenset()
        assert tokens_for_cpu(None) == frozenset()  # type: ignore[arg-type]


class TestTokenizeAndLookup:
    def test_korean_bigram_intel_i5(self, seeded_index):
        result = tokenize_and_lookup(seeded_index, "인텔 i5")
        assert result == ["Intel Core i5-1335U", "Intel Core i5-13420H"]

    def test_unigram_i5_equivalent_to_bigram(self, seeded_index):
        bigram = tokenize_and_lookup(seeded_index, "인텔 i5")
        unigram = tokenize_and_lookup(seeded_index, "i5")
        assert bigram == unigram

    def test_korean_ryzen_7(self, seeded_index):
        result = tokenize_and_lookup(seeded_index, "라이젠 7")
        assert result == ["AMD Ryzen 7 7840U"]

    def test_brand_intel_returns_all_intel(self, seeded_index):
        result = tokenize_and_lookup(seeded_index, "인텔")
        assert set(result) == {
            "Intel Core Ultra 5-125H",
            "Intel Core Ultra 7-155H",
            "Intel Core i5-1335U",
            "Intel Core i5-13420H",
            "Intel Core i7-1355U",
        }

    def test_apple_m3_pro_intersection(self, seeded_index):
        result = tokenize_and_lookup(seeded_index, "애플 m3 프로")
        assert result == ["Apple M3 Pro"]

    def test_missing_tier_returns_empty(self, seeded_index):
        assert tokenize_and_lookup(seeded_index, "i3") == []

    def test_empty_input_returns_empty(self, seeded_index):
        assert tokenize_and_lookup(seeded_index, "") == []
        assert tokenize_and_lookup(seeded_index, "   ") == []

    def test_unknown_tokens_skipped(self, seeded_index):
        result = tokenize_and_lookup(seeded_index, "고성능 인텔 i7 노트북")
        assert result == ["Intel Core i7-1355U"]

    def test_intel_model_number_only(self, seeded_index):
        result = tokenize_and_lookup(seeded_index, "1335u")
        assert result == ["Intel Core i5-1335U"]

    def test_intel_core_keyword(self, seeded_index):
        result = tokenize_and_lookup(seeded_index, "코어 i7")
        assert result == ["Intel Core i7-1355U"]


class TestBuildWhereIntegration:
    def setup_method(self):
        reset_cpu_index()

    def teardown_method(self):
        reset_cpu_index()

    def test_in_clause_for_matched_cpu(self, monkeypatch, seeded_index):
        monkeypatch.setattr(cpu_index, "_INDEX_CACHE", seeded_index)
        where, params = nodes._build_where({"cpu": "인텔 i5"})
        assert "cpu IN (?,?)" in where
        assert set(params) == {
            "Intel Core i5-1335U",
            "Intel Core i5-13420H",
        }

    def test_no_match_emits_false_clause(self, monkeypatch, seeded_index):
        monkeypatch.setattr(cpu_index, "_INDEX_CACHE", seeded_index)
        where, params = nodes._build_where({"cpu": "i3"})
        assert "1=0" in where
        assert params == []

    def test_brand_intel_in_clause(self, monkeypatch, seeded_index):
        monkeypatch.setattr(cpu_index, "_INDEX_CACHE", seeded_index)
        where, params = nodes._build_where({"cpu": "인텔"})
        assert "cpu IN (?,?,?,?,?)" in where
        assert len(params) == 5


class TestGetCpuIndexRetry:
    def setup_method(self):
        reset_cpu_index()

    def teardown_method(self):
        reset_cpu_index()

    def test_missing_table_returns_empty_and_does_not_cache(
        self, monkeypatch, tmp_path, capsys
    ):
        db_file = tmp_path / "missing.db"
        monkeypatch.setenv("DB_PATH", str(db_file))

        result = cpu_index.get_cpu_index()

        assert result == {}
        assert cpu_index._INDEX_CACHE is None
        captured = capsys.readouterr()
        assert "[cpu_index] WARN" in captured.err

    def test_empty_laptops_table_returns_empty_and_does_not_cache(
        self, monkeypatch, tmp_path, capsys
    ):
        db_file = tmp_path / "empty.db"
        conn = sqlite3.connect(str(db_file))
        conn.execute("CREATE TABLE laptops (cpu TEXT)")
        conn.commit()
        conn.close()
        monkeypatch.setenv("DB_PATH", str(db_file))

        result = cpu_index.get_cpu_index()

        assert result == {}
        assert cpu_index._INDEX_CACHE is None
        captured = capsys.readouterr()
        assert "[cpu_index] WARN" in captured.err

    def test_relative_db_path_anchors_to_project_root(self, monkeypatch):
        monkeypatch.setenv("DB_PATH", "db/laptops.db")
        resolved = Path(resolve_db_path())
        assert resolved.is_absolute()
        assert resolved.name == "laptops.db"
        assert resolved.parent.name == "db"
        assert resolved.parent.parent.name == "Demo"

    def test_unset_db_path_defaults_to_project_root(self, monkeypatch):
        monkeypatch.delenv("DB_PATH", raising=False)
        resolved = Path(resolve_db_path())
        assert resolved.is_absolute()
        assert resolved.parts[-2:] == ("db", "laptops.db")

    def test_absolute_db_path_passes_through(self, monkeypatch, tmp_path):
        absolute = tmp_path / "elsewhere.db"
        monkeypatch.setenv("DB_PATH", str(absolute))
        assert resolve_db_path() == str(absolute)

    def test_retry_succeeds_after_seeding(self, monkeypatch, tmp_path):
        db_file = tmp_path / "lazy.db"
        conn = sqlite3.connect(str(db_file))
        conn.execute("CREATE TABLE laptops (cpu TEXT)")
        conn.commit()
        conn.close()
        monkeypatch.setenv("DB_PATH", str(db_file))

        first = cpu_index.get_cpu_index()
        assert first == {}
        assert cpu_index._INDEX_CACHE is None

        conn = sqlite3.connect(str(db_file))
        conn.executemany(
            "INSERT INTO laptops (cpu) VALUES (?)", [(c,) for c in SEED_CPUS]
        )
        conn.commit()
        conn.close()

        second = cpu_index.get_cpu_index()
        assert second
        assert "intel" in second
        assert cpu_index._INDEX_CACHE is second
