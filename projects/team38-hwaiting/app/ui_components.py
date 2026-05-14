"""Streamlit UI 헬퍼 — 사이드바·후보 카드·비교표 (PRD US-014, US-016)."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Callable

import streamlit as st

from graph.state import SLOT_KEYS, LaptopChatState, filled_count

PLACEHOLDER_IMG = Path(__file__).parent / "static" / "no_image.png"

_SLOT_LABELS = {
    "screen_inch": "화면 인치",
    "weight_kg": "무게(kg)",
    "os": "OS",
    "resolution": "해상도",
    "brightness_nits": "밝기(nit)",
    "cpu": "CPU",
    "ram_gb": "RAM(GB)",
    "storage_gb": "저장(GB)",
    "price_krw": "예산(원)",
}


def _format_slot_value(key: str, value: Any) -> str:
    if value is None:
        return "—"
    if key == "price_krw" and isinstance(value, (int, float)):
        return f"{int(value):,}"
    return str(value)


def render_sidebar(state: LaptopChatState, on_reset: Callable[[], None]) -> None:
    with st.sidebar:
        st.header("진행률")
        slots = state.get("slots") or {}
        inferred = set(state.get("inferred_keys") or [])
        n = filled_count(slots)
        st.progress(n / 9.0, text=f"{n}/9 채움")

        st.divider()
        st.subheader("9개 조건")
        if inferred:
            st.caption("🔮 = 옵션에서 골라주신 값입니다. 다음 메시지에서 자유롭게 바꾸실 수 있어요.")
        for k in SLOT_KEYS:
            badge = " 🔮" if k in inferred else ""
            st.markdown(
                f"**{_SLOT_LABELS[k]}**: {_format_slot_value(k, slots.get(k))}{badge}"
            )

        st.divider()
        st.subheader("🔧 백엔드 상태")

        is_complete = state.get("is_complete", False)
        turn = state.get("turn_count") or 0
        sql_clause = state.get("sql_clause")
        candidates = state.get("candidates") or []
        use_case = state.get("use_case")

        if use_case:
            st.markdown(f"**사용 목적**: `{use_case}`")

        st.markdown(f"**턴 수**: `{turn}`")

        if is_complete:
            st.success("Node B → D → E → F 실행됨")
        elif turn > 0:
            st.info("Node B → C 실행됨 (슬롯 수집 중)")

        if sql_clause:
            where_sql, params = sql_clause
            st.markdown("**생성된 SQL WHERE 절**")
            st.code(
                f"SELECT * FROM laptops\nWHERE {where_sql}\nORDER BY price_krw ASC LIMIT 5",
                language="sql",
            )
            st.markdown(f"**파라미터**: `{params}`")
            st.markdown(f"**매칭 결과**: `{len(candidates)}건`")

        st.divider()
        if st.button("대화 초기화", use_container_width=True):
            on_reset()


def _render_card(c: dict[str, Any]) -> None:
    thumb = c.get("thumbnail_url")
    if thumb:
        st.image(thumb, use_container_width=True)
    elif PLACEHOLDER_IMG.exists():
        st.image(str(PLACEHOLDER_IMG), use_container_width=True)
    else:
        st.markdown("### 🖼️")

    st.subheader(c.get("product_name") or "(이름 없음)")

    price = c.get("price_krw")
    if isinstance(price, int):
        st.metric("가격", f"{price:,}원")

    with st.expander("스펙 자세히"):
        rows = {
            "화면": f"{c.get('screen_inch')}\"",
            "무게": f"{c.get('weight_kg')}kg",
            "OS": c.get("os"),
            "해상도": c.get("resolution"),
            "밝기": f"{c.get('brightness_nits')}nit" if c.get("brightness_nits") else "—",
            "CPU": c.get("cpu"),
            "RAM": f"{c.get('ram_gb')}GB",
            "저장": f"{c.get('storage_gb')}GB",
        }
        for k, v in rows.items():
            st.write(f"- **{k}**: {v}")

    if c.get("detail_url"):
        st.link_button("다나와에서 보기", c["detail_url"], use_container_width=True)


def render_results(candidates: list[dict[str, Any]]) -> None:
    if not candidates:
        return
    st.divider()
    st.markdown("### 추천 결과")

    n = len(candidates)
    if n <= 3:
        cols = st.columns(n)
        for col, c in zip(cols, candidates):
            with col:
                _render_card(c)
    else:
        first_row = st.columns(3)
        for col, c in zip(first_row, candidates[:3]):
            with col:
                _render_card(c)
        second_row = st.columns(3)
        rest = candidates[3:]
        for i, col in enumerate(second_row):
            with col:
                if i < len(rest):
                    _render_card(rest[i])
                else:
                    st.empty()

    st.markdown("#### 9개 스펙 비교")
    table_rows = []
    for c in candidates:
        table_rows.append(
            {
                "제품명": c.get("product_name"),
                "화면": c.get("screen_inch"),
                "무게(kg)": c.get("weight_kg"),
                "OS": c.get("os"),
                "해상도": c.get("resolution"),
                "밝기(nit)": c.get("brightness_nits"),
                "CPU": c.get("cpu"),
                "RAM(GB)": c.get("ram_gb"),
                "저장(GB)": c.get("storage_gb"),
                "가격(원)": c.get("price_krw"),
            }
        )
    st.dataframe(table_rows, use_container_width=True, hide_index=True)
