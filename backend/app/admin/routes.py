from __future__ import annotations

import io

from flask import Blueprint, flash, redirect, render_template, request, send_file, url_for

from app.core.exceptions import AppError
from app.services import (
    assistant_service,
    incident_report_export,
    incident_report_service,
    picture_service,
    site_service,
    speech_service,
)




admin_bp = Blueprint(
    "admin",
    __name__,
    url_prefix="/admin",
    template_folder="templates",
)


def _site_name_lookup() -> dict[str, str]:
    return {s["site_id"]: s["site_name"] for s in site_service.list_sites()}


@admin_bp.get("/")
def home():
    return render_template(
        "home.html",
        user_count=len(assistant_service.list_assistants()),
        site_count=len(site_service.list_sites()),
        report_count=len(incident_report_service.list_incident_reports()),
        voice_count=len(speech_service.list_notes()),
        picture_count=len(picture_service.list_pictures()),
    )


@admin_bp.get("/users")
def users():
    return render_template("users.html", users=assistant_service.list_assistants())


@admin_bp.post("/users")
def create_user():
    form = request.form
    try:
        assistant_service.create_assistant(
            full_name=form.get("full_name", ""),
            email=form.get("email", ""),
            password=form.get("password", ""),
            role=form.get("role", ""),
            phone=form.get("phone", ""),
        )
        flash(f"User '{form.get('full_name')}' created.", "success")
    except AppError as exc:
        flash(exc.message, "error")
    return redirect(url_for("admin.users"))


@admin_bp.post("/users/<assistant_id>/delete")
def delete_user(assistant_id: str):
    try:
        assistant_service.delete_assistant(assistant_id)
        flash("User deleted.", "success")
    except AppError as exc:
        flash(exc.message, "error")
    return redirect(url_for("admin.users"))


@admin_bp.get("/sites")
def sites():
    return render_template(
        "sites.html",
        sites=site_service.list_sites(),
        users=assistant_service.list_assistants(),
    )


@admin_bp.post("/sites")
def create_site():
    form = request.form
    try:
        site_service.create_site(
            site_name=form.get("site_name", ""),
            address=form.get("address", ""),
            assigned_assistant_id=form.get("assigned_assistant_id", ""),
            site_code=form.get("site_code", ""),
            status=form.get("status", "active"),
            phase=form.get("phase", ""),
        )
        flash(f"Site '{form.get('site_name')}' created.", "success")
    except AppError as exc:
        flash(exc.message, "error")
    return redirect(url_for("admin.sites"))


@admin_bp.post("/sites/<site_id>/delete")
def delete_site(site_id: str):
    try:
        site_service.delete_site(site_id)
        flash("Site deleted.", "success")
    except AppError as exc:
        flash(exc.message, "error")
    return redirect(url_for("admin.sites"))


@admin_bp.get("/media")
def media():
    return render_template(
        "media.html",
        voice_notes=speech_service.list_notes(),
        pictures=picture_service.list_pictures(),
    )










@admin_bp.get("/reports")
def reports():
    sites_by_id = _site_name_lookup()
    return render_template(
        "reports.html",
        incident_reports=incident_report_service.list_incident_reports(),
        sites_by_id=sites_by_id,
    )


@admin_bp.get("/reports/incident/<report_id>")
def incident_report_detail(report_id: str):
    try:
        report = incident_report_service.get_incident_report(report_id)
    except AppError as exc:
        flash(exc.message, "error")
        return redirect(url_for("admin.reports"))
    return render_template(
        "report_incident_detail.html",
        report=report,
        field_sections=incident_report_service.FIELD_SECTIONS,
        field_labels=incident_report_service.FIELD_LABELS,
        site_name=_site_name_lookup().get(report["site_id"], report["site_id"]),
    )


@admin_bp.get("/reports/incident/<report_id>/export")
def export_incident_report(report_id: str):
    try:
        report = incident_report_service.get_incident_report(report_id)
    except AppError as exc:
        flash(exc.message, "error")
        return redirect(url_for("admin.reports"))
    xlsx_bytes = incident_report_export.export_to_xlsx(report)
    return send_file(
        io.BytesIO(xlsx_bytes),
        mimetype="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        as_attachment=True,
        download_name=incident_report_export.export_filename(report),
    )


@admin_bp.get("/reports/incident/<report_id>/pdf")
def incident_report_pdf(report_id: str):
    try:
        pdf_bytes, report = incident_report_service.get_pdf_bytes(report_id)
    except AppError as exc:
        flash(exc.message, "error")
        return redirect(url_for("admin.reports"))
    from app.services import incident_report_pdf as pdf_service

    return send_file(
        io.BytesIO(pdf_bytes),
        mimetype="application/pdf",
        as_attachment=False,
        download_name=pdf_service.pdf_filename(report),
    )


@admin_bp.post("/reports/incident/<report_id>/delete")
def delete_incident_report(report_id: str):
    try:
        incident_report_service.delete_incident_report(report_id)
        flash("Incident report deleted.", "success")
    except AppError as exc:
        flash(exc.message, "error")
    return redirect(url_for("admin.reports"))
