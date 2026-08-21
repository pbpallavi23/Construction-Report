from __future__ import annotations

from typing import Any

from app.core.exceptions import ValidationAppError
from app.core.storage import REPORT_PDF_SUBDIR, absolute_path, delete_file, save_bytes
from app.core.utils import new_id, to_plain, today_iso, utc_now_iso
from app.persistence import repositories
from app.services import ai_service

REPORT_TYPE = "incident"




FIELD_LABELS: dict[str, str] = {
    "project": "Project",
    "job_no": "Job No",
    "prepared_by": "Prepared By",
    "received_by": "Received by",
    "report_date": "Date",
    "team": "Team",
    "distribution": "Distribution",
    "incident_type": "Type of Incident",
    "category": "Category of Incident",
    "person_name": "1. Name of person who was involved in the incident",
    "person_address": "Address of person who was involved in the incident",
    "employer_name": "Name of Employer",
    "employer_address": "Address of Employer",
    "employer_phone": "Telephone Number of Employer",
    "site_address": "2. Site Address (including Postcode)",
    "incident_location": "3. Location of the incident",
    "incident_date": "4a. Date of incident (DD/MM/YYYY)",
    "incident_time": "4b. Time of incident (24 hour clock)",
    "description": "5. Description of Incident",
    "injured_body_part": "6. Injured Part of Body",
    "was_injured": "7. Was the person injured",
    "accident_book_completed": "8. If yes has the accident book been completed",
    "riddor_reportable": "9. Was the incident RIDDOR reportable",
    "time_lost": "10. Was any time lost due to the incident",
    "time_lost_days": "If Yes, amount of time lost (days)",
    "went_to_hospital": "11. Did the Injured Person (IP) go to hospital",
    "hospital_details": "If Yes, please give details",
    "saw_gp": "12. Did the Injured Person (IP) see a GP",
    "gp_details": "If Yes, please give details",
    "action_taken": "13. Details of any action taken as a result of matters identified in item 5",
    "further_action": "14. Details of any further action considered necessary",
    "reporter_name": "17. Name of person making the report",
    "reporter_position": "17. Position of person making the report",
    "report_handed_date": "Date report handed to Line Manager",
    "signed_off_by_name": "18. Name of person signing off the incident",
    "signed_off_by_position": "17. Position of person signing off the incident",
    "signed_off_date": "Date incident signed off",
}

FIELD_KEYS: list[str] = list(FIELD_LABELS.keys())




NON_AI_FIELDS: set[str] = {
    "prepared_by",
    "received_by",
    "distribution",
    "person_address",
    "employer_name",
    "employer_address",
    "employer_phone",
    "reporter_name",
    "reporter_position",
    "report_handed_date",
    "signed_off_by_name",
    "signed_off_by_position",
    "signed_off_date",
}

INCIDENT_TYPES = ["accident", "near_miss", "dangerous_occurrence"]

ACCIDENT_CATEGORIES = [
    "Slips, Trips, and Falls", "Falls from Height", "Manual Handling",
    "Struck by Moving or Falling Objects", "Contact with Moving Machinery",
    "Struck by Moving Vehicles", "Electric Shock or Burns",
    "Exposure to Harmful Substances", "Collapse of Structures",
    "Environmental", "Medical Emergency (eg Stroke, Heart)",
    "Vehicle/Plant-Related (eg Crash)", "Incorrect / No PPE",
]
NEAR_MISS_CATEGORIES = [
    "Falls from Height (Prevented)", "Slips, Trips, and Falls (Prevented)",
    "Struck by Falling Objects (Prevented)",
    "Vehicle or Equipment Collisions (Prevented)",
    "Structural Collapse (Prevented)", "Service Near Misses (Prevented)",
    "Equipment or Tool Malfunctions (Prevented)", "Fire or Explosion (Prevented)",
    "Exposure to Harmful Substances (Prevented)",
    "Crane or Lifting Equipment Incidents (Prevented)",
    "Signing lighting and guarding, security (Improved)",
    "Environmental (Prevented)", "Manual Handling Injuries (Prevented)",
    "Incorrect / No PPE (Prevented)",
]
DANGEROUS_OCCURRENCE_CATEGORIES = [
    "Escape of Substances (eg Asbestos) (Reported under RIDDOR)",
    "Pressure Systems (Reported under RIDDOR)",
    "Transport-Related Incidents (Overturning) (Reported under RIDDOR)",
    "Security (Intruder) & Safe Guarding", "Confined Space (person not injured)",
    "Structural Failures Collapse or partial collapse",
    "Electrical Incidents (eg Cable Strike)",
    "Equipment and Machinery Failures (eg Cutting Tool Blade Failure)",
    "Vehicle/Plant-Related (eg Crash) no injury", "Explosions and Fires",
    "Environmental (eg spill, release of dust)", "Flood / Risk of Drowning",
]
BODY_PARTS = [
    "N/A", "Medical", "Head", "Eye(s)", "Face", "Nose", "Ears", "Neck",
    "Shoulder", "Arm", "Wrist", "Hand", "Fingers", "Torso", "Ribs", "Back",
    "Leg", "Knee", "Ankle", "Foot", "Toes",
]

_AI_FIELD_KEYS = [k for k in FIELD_KEYS if k not in NON_AI_FIELDS]




FIELD_SECTIONS: list[tuple[str, list[str]]] = [
    ("Report Details", [
        "project", "job_no", "prepared_by", "received_by", "report_date",
        "team", "distribution",
    ]),
    ("Incident Classification", ["incident_type", "category"]),
    ("Person Involved", [
        "person_name", "person_address", "employer_name", "employer_address",
        "employer_phone",
    ]),
    ("Site & Incident Details", [
        "site_address", "incident_location", "incident_date", "incident_time",
    ]),
    ("Description of Incident", ["description"]),
    ("Injury Details", [
        "injured_body_part", "was_injured", "accident_book_completed",
        "riddor_reportable",
    ]),
    ("Time Lost & Medical", [
        "time_lost", "time_lost_days", "went_to_hospital", "hospital_details",
        "saw_gp", "gp_details",
    ]),
    ("Actions", ["action_taken", "further_action"]),
    ("Sign-off", [
        "reporter_name", "reporter_position", "report_handed_date",
        "signed_off_by_name", "signed_off_by_position", "signed_off_date",
    ]),
]

_GUIDANCE = (
    "incident_type must be one of: accident, near_miss, dangerous_occurrence.\n"
    "category must be one of these, matching the chosen incident_type:\n"
    f"  accident: {', '.join(ACCIDENT_CATEGORIES)}\n"
    f"  near_miss: {', '.join(NEAR_MISS_CATEGORIES)}\n"
    f"  dangerous_occurrence: {', '.join(DANGEROUS_OCCURRENCE_CATEGORIES)}\n"
    f"injured_body_part must be one of: {', '.join(BODY_PARTS)} (or null if no injury).\n"
    "was_injured, accident_book_completed, riddor_reportable, time_lost, "
    "went_to_hospital, saw_gp must each be 'yes', 'no', or null.\n"
    "description should be a clear factual account of what happened, in "
    "plain English, based only on the material given."
)


def options() -> dict[str, Any]:
    """Reference data for the frontend's dropdowns."""
    return {
        "incident_types": INCIDENT_TYPES,
        "categories": {
            "accident": ACCIDENT_CATEGORIES,
            "near_miss": NEAR_MISS_CATEGORIES,
            "dangerous_occurrence": DANGEROUS_OCCURRENCE_CATEGORIES,
        },
        "body_parts": BODY_PARTS,
        "field_labels": FIELD_LABELS,
    }


def generate_draft(site_id: str) -> dict[str, Any]:
    """Auto-fills what it can from the site's pictures and voice notes.
    Nothing is saved to the DB at this point - the user reviews/edits the
    result and only approve() persists it."""
    if repositories.sites.get(site_id) is None:
        raise ValidationAppError(f"Site '{site_id}' does not exist.")

    pictures = repositories.pictures.list(site_id)
    notes = repositories.voice_notes.list(site_id)

    result = ai_service.autofill_incident_report(
        pictures=pictures, notes=notes, field_keys=_AI_FIELD_KEYS, guidance=_GUIDANCE
    )

    fields: dict[str, Any] = {key: None for key in FIELD_KEYS}
    fields.update(result["fields"])
    fields["report_date"] = today_iso()

    return {
        "site_id": site_id,
        "fields": fields,
        "ai_available": result["ai_available"],
        "used_picture_ids": result["used_picture_ids"],
        "used_note_ids": result["used_note_ids"],
    }


def list_incident_reports(site_id: str | None = None) -> list[dict[str, Any]]:
    reports = repositories.reports.list(site_id)
    incidents = [r for r in reports if r.get("report_type") == REPORT_TYPE]
    return sorted(incidents, key=lambda r: r["report_date"], reverse=True)


def get_incident_report(report_id: str) -> dict[str, Any]:
    row = repositories.reports.get(report_id)
    if row is None or row.get("report_type") != REPORT_TYPE:
        raise ValidationAppError(f"Incident report '{report_id}' was not found.")
    return row


def approve(
    site_id: str,
    fields: dict[str, Any],
    user_id: str | None = None,
) -> dict[str, Any]:
    """Saves the user-approved (and possibly hand-edited) incident report.
    This is the only place an incident report is written to the DB, per
    the requirement that nothing persists until the user approves it. A
    PDF rendering of the report (matching the official form's layout) is
    generated at the same time and saved alongside it - the fields remain
    the editable, queryable record, and the PDF is the fixed, shareable
    copy of what was approved."""
    site = repositories.sites.get(site_id)
    if site is None:
        raise ValidationAppError(f"Site '{site_id}' does not exist.")

    payload = to_plain(fields)
    clean_fields: dict[str, Any] = {key: payload.get(key) for key in FIELD_KEYS}
    if not clean_fields.get("report_date"):
        clean_fields["report_date"] = today_iso()

    now = utc_now_iso()
    record = {
        "id": new_id("incident"),
        "site_id": site_id,
        "report_type": REPORT_TYPE,
        "status": "signed_off",
        "report_date": clean_fields["report_date"],
        "approved_by": user_id,
        "created_at": now,
        "updated_at": now,
        "fields": clean_fields,
    }



    from app.services import incident_report_pdf

    pdf_bytes = incident_report_pdf.build_pdf(
        record, site_name=site.get("site_name", "")
    )
    record["pdf_path"] = save_bytes(
        pdf_bytes, REPORT_PDF_SUBDIR, f"{record['id']}.pdf"
    )

    return repositories.reports.add(record)


def get_pdf_bytes(report_id: str) -> tuple[bytes, dict[str, Any]]:
    """Returns the report's PDF bytes, generating (and backfilling) it on
    the fly for any record saved before PDF generation existed."""
    report = get_incident_report(report_id)
    pdf_path = report.get("pdf_path")
    if pdf_path:
        try:
            with open(absolute_path(pdf_path), "rb") as f:
                return f.read(), report
        except OSError:
            pass

    from app.services import incident_report_pdf

    site = repositories.sites.get(report["site_id"])
    pdf_bytes = incident_report_pdf.build_pdf(
        report, site_name=(site or {}).get("site_name", "")
    )
    new_path = save_bytes(pdf_bytes, REPORT_PDF_SUBDIR, f"{report['id']}.pdf")
    updated = repositories.reports.update(report_id, {"pdf_path": new_path})
    return pdf_bytes, (updated or report)


def delete_incident_report(report_id: str) -> None:
    report = get_incident_report(report_id)
    repositories.reports.delete(report_id)
    if report.get("pdf_path"):
        delete_file(report["pdf_path"])
