from __future__ import annotations

import io
import re
from typing import Any

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (
    KeepTogether,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

from app.services.incident_report_service import FIELD_LABELS, FIELD_SECTIONS

_BRAND = colors.HexColor("#0b5394")
_LINE = colors.HexColor("#e0e5ea")
_BLANK = colors.HexColor("#b42318")

_styles = getSampleStyleSheet()
_title_style = ParagraphStyle(
    "IRTitle", parent=_styles["Title"], fontName="Helvetica-Bold",
    fontSize=16, textColor=_BRAND, spaceAfter=2,
)
_meta_style = ParagraphStyle(
    "IRMeta", parent=_styles["Normal"], fontName="Helvetica",
    fontSize=9, textColor=colors.HexColor("#555555"),
)
_section_style = ParagraphStyle(
    "IRSection", parent=_styles["Heading2"], fontName="Helvetica-Bold",
    fontSize=11, textColor=_BRAND, spaceBefore=10, spaceAfter=4,
)
_label_style = ParagraphStyle(
    "IRLabel", parent=_styles["Normal"], fontName="Helvetica-Bold",
    fontSize=8.5, textColor=colors.HexColor("#555555"),
)
_value_style = ParagraphStyle(
    "IRValue", parent=_styles["Normal"], fontName="Helvetica",
    fontSize=10, textColor=colors.black, leading=13,
)
_blank_style = ParagraphStyle(
    "IRBlank", parent=_value_style, textColor=_BLANK, fontName="Helvetica-Oblique",
)

_ISO_DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")


def _to_uk_date(value: str) -> str:
    if _ISO_DATE_RE.match(value):
        year, month, day = value.split("-")
        return f"{day}/{month}/{year}"
    return value


def _display_value(key: str, value: Any) -> str:
    if value in (None, ""):
        return ""
    text = str(value)
    if key == "incident_type":
        return text.replace("_", " ").title()
    if key in {
        "was_injured", "accident_book_completed", "riddor_reportable",
        "time_lost", "went_to_hospital", "saw_gp",
    }:
        return text.strip().capitalize()
    if key in {"report_date"}:
        return _to_uk_date(text)
    return text


def _render_field(key: str, value: Any) -> Table:
    label = FIELD_LABELS.get(key, key)
    display = _display_value(key, value)
    value_para = Paragraph(
        display if display else "(blank — not yet filled in)",
        _value_style if display else _blank_style,
    )
    row = Table(
        [[Paragraph(label, _label_style)], [value_para]],
        colWidths=[170 * mm],
    )
    row.setStyle(TableStyle([
        ("BOTTOMPADDING", (0, 0), (-1, 0), 1),
        ("TOPPADDING", (0, 0), (-1, -1), 2),
        ("BOTTOMPADDING", (0, 1), (-1, 1), 6),
        ("LINEBELOW", (0, 1), (-1, 1), 0.5, _LINE),
        ("LEFTPADDING", (0, 0), (-1, -1), 0),
        ("RIGHTPADDING", (0, 0), (-1, -1), 0),
    ]))
    return row


def build_pdf(report: dict[str, Any], site_name: str = "") -> bytes:
    """Renders a saved incident report as a PDF, in the same field order and
    grouping as the official Incident_Report.xlsx form. Blank fields are
    shown as blank (in red, matching the app/admin convention) rather than
    invented."""
    fields = report.get("fields", {})
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer, pagesize=A4,
        topMargin=18 * mm, bottomMargin=18 * mm,
        leftMargin=20 * mm, rightMargin=20 * mm,
        title=f"Incident Report {report.get('id', '')}",
    )

    story: list[Any] = []
    story.append(Paragraph("INCIDENT REPORT FORM (03-045-04)", _title_style))
    meta_bits = [f"Report ID: {report.get('id', '—')}"]
    if site_name:
        meta_bits.append(f"Site: {site_name}")
    meta_bits.append(f"Status: {report.get('status', '—')}")
    if report.get("approved_by"):
        meta_bits.append(f"Approved by: {report['approved_by']}")
    story.append(Paragraph(" &nbsp;·&nbsp; ".join(meta_bits), _meta_style))
    story.append(Spacer(1, 6 * mm))

    for section_title, keys in FIELD_SECTIONS:
        section_block: list[Any] = [Paragraph(section_title, _section_style)]
        for key in keys:
            section_block.append(_render_field(key, fields.get(key)))
        story.append(KeepTogether(section_block))

    doc.build(story)
    buffer.seek(0)
    return buffer.read()


def pdf_filename(report: dict[str, Any]) -> str:
    date_part = (report.get("report_date") or "undated").replace("/", "-")
    return f"Incident_Report_{report.get('id', 'report')}_{date_part}.pdf"
