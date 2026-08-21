from __future__ import annotations

import io

from flask import Blueprint, request, send_file

from app.api.deps import current_assistant, require_auth
from app.api.responses import body, json_ok, require_fields
from app.services import incident_report_export, incident_report_service

bp = Blueprint("reports", __name__)









@bp.get("/reports/incident/options")
@require_auth
def incident_options():
    return json_ok(incident_report_service.options())


@bp.post("/reports/incident/generate")
@require_auth
def generate_incident_draft():
    data = body()
    require_fields(data, "site_id")
    return json_ok(incident_report_service.generate_draft(data["site_id"]))


@bp.post("/reports/incident/approve")
@require_auth
def approve_incident_report():
    data = body()
    require_fields(data, "site_id")
    fields = data.get("fields", {})
    if not isinstance(fields, dict):
        fields = {}
    user_id = current_assistant().get("assistant_id")
    return json_ok(
        incident_report_service.approve(data["site_id"], fields, user_id)
    )


@bp.get("/reports/incident")
@require_auth
def list_incident_reports():
    site_id = request.args.get("site_id")
    return json_ok(incident_report_service.list_incident_reports(site_id))


@bp.get("/reports/incident/<report_id>")
@require_auth
def get_incident_report(report_id: str):
    return json_ok(incident_report_service.get_incident_report(report_id))


@bp.delete("/reports/incident/<report_id>")
@require_auth
def delete_incident_report(report_id: str):
    incident_report_service.delete_incident_report(report_id)
    return json_ok({"id": report_id, "deleted": True})


@bp.get("/reports/incident/<report_id>/export")
@require_auth
def export_incident_report(report_id: str):
    """Downloads the saved report filled into the official
    Incident_Report.xlsx template - same layout, styling, and dropdown
    sheets as the original form, just with this report's values written
    into its input cells."""
    report = incident_report_service.get_incident_report(report_id)
    xlsx_bytes = incident_report_export.export_to_xlsx(report)
    return send_file(
        io.BytesIO(xlsx_bytes),
        mimetype="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        as_attachment=True,
        download_name=incident_report_export.export_filename(report),
    )


@bp.get("/reports/incident/<report_id>/pdf")
@require_auth
def incident_report_pdf(report_id: str):
    """The saved, shareable copy of the report: a PDF laid out the same
    way as the official form. Generated once at approve() time and stored
    alongside the record; served inline so it can be previewed in the
    app/browser as well as downloaded."""
    pdf_bytes, report = incident_report_service.get_pdf_bytes(report_id)
    from app.services import incident_report_pdf as pdf_service

    return send_file(
        io.BytesIO(pdf_bytes),
        mimetype="application/pdf",
        as_attachment=False,
        download_name=pdf_service.pdf_filename(report),
    )
