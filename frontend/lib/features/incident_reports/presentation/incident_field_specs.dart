import 'package:flutter/material.dart';

enum IncidentFieldType {
  text,
  multiline,
  dropdownYesNo,
  dropdownIncidentType,
  dropdownCategory,
  dropdownBodyPart,
}

class IncidentFieldSpec {
  const IncidentFieldSpec(this.key, this.label, this.type);
  final String key;
  final String label;
  final IncidentFieldType type;
}

class IncidentSection {
  const IncidentSection(this.title, this.icon, this.fields);
  final String title;
  final IconData icon;
  final List<IncidentFieldSpec> fields;
}



const List<IncidentSection> incidentFormSections = [
  IncidentSection('Incident Classification', Icons.category_outlined, [
    IncidentFieldSpec('incident_type', 'Type of Incident', IncidentFieldType.dropdownIncidentType),
    IncidentFieldSpec('category', 'Category of Incident', IncidentFieldType.dropdownCategory),
  ]),
  IncidentSection('What Happened', Icons.notes_rounded, [
    IncidentFieldSpec('description', 'Description of Incident', IncidentFieldType.multiline),
    IncidentFieldSpec('injured_body_part', 'Injured Part of Body', IncidentFieldType.dropdownBodyPart),
  ]),
  IncidentSection('Where & When', Icons.place_outlined, [
    IncidentFieldSpec('site_address', 'Site Address (including Postcode)', IncidentFieldType.multiline),
    IncidentFieldSpec('incident_location', 'Location of the Incident', IncidentFieldType.text),
    IncidentFieldSpec('incident_date', 'Date of Incident (DD/MM/YYYY)', IncidentFieldType.text),
    IncidentFieldSpec('incident_time', 'Time of Incident (24hr)', IncidentFieldType.text),
  ]),
  IncidentSection('Person Involved', Icons.person_outline_rounded, [
    IncidentFieldSpec('person_name', 'Name of Person Involved', IncidentFieldType.text),
    IncidentFieldSpec('person_address', 'Address of Person Involved', IncidentFieldType.multiline),
    IncidentFieldSpec('employer_name', 'Name of Employer', IncidentFieldType.text),
    IncidentFieldSpec('employer_address', 'Address of Employer', IncidentFieldType.multiline),
    IncidentFieldSpec('employer_phone', 'Telephone Number of Employer', IncidentFieldType.text),
  ]),
  IncidentSection('Injury & Reporting', Icons.health_and_safety_outlined, [
    IncidentFieldSpec('was_injured', 'Was the Person Injured', IncidentFieldType.dropdownYesNo),
    IncidentFieldSpec('accident_book_completed', 'Accident Book Completed', IncidentFieldType.dropdownYesNo),
    IncidentFieldSpec('riddor_reportable', 'RIDDOR Reportable', IncidentFieldType.dropdownYesNo),
  ]),
  IncidentSection('Time Lost & Medical', Icons.local_hospital_outlined, [
    IncidentFieldSpec('time_lost', 'Was Any Time Lost', IncidentFieldType.dropdownYesNo),
    IncidentFieldSpec('time_lost_days', 'Amount of Time Lost (days)', IncidentFieldType.text),
    IncidentFieldSpec('went_to_hospital', 'Did IP Go to Hospital', IncidentFieldType.dropdownYesNo),
    IncidentFieldSpec('hospital_details', 'Hospital Details', IncidentFieldType.multiline),
    IncidentFieldSpec('saw_gp', 'Did IP See a GP', IncidentFieldType.dropdownYesNo),
    IncidentFieldSpec('gp_details', 'GP Details', IncidentFieldType.multiline),
  ]),
  IncidentSection('Actions', Icons.build_circle_outlined, [
    IncidentFieldSpec('action_taken', 'Action Taken (re: item 5)', IncidentFieldType.multiline),
    IncidentFieldSpec('further_action', 'Further Action Considered Necessary', IncidentFieldType.multiline),
  ]),
  IncidentSection('Report Admin', Icons.assignment_ind_outlined, [
    IncidentFieldSpec('project', 'Project', IncidentFieldType.text),
    IncidentFieldSpec('job_no', 'Job No', IncidentFieldType.text),
    IncidentFieldSpec('prepared_by', 'Prepared By', IncidentFieldType.text),
    IncidentFieldSpec('received_by', 'Received By', IncidentFieldType.text),
    IncidentFieldSpec('team', 'Team', IncidentFieldType.text),
    IncidentFieldSpec('distribution', 'Distribution', IncidentFieldType.text),
    IncidentFieldSpec('reporter_name', 'Name of Person Making the Report', IncidentFieldType.text),
    IncidentFieldSpec('reporter_position', 'Position of Person Making the Report', IncidentFieldType.text),
    IncidentFieldSpec('report_handed_date', 'Date Report Handed to Line Manager', IncidentFieldType.text),
    IncidentFieldSpec('signed_off_by_name', 'Name of Person Signing Off', IncidentFieldType.text),
    IncidentFieldSpec('signed_off_by_position', 'Position of Person Signing Off', IncidentFieldType.text),
    IncidentFieldSpec('signed_off_date', 'Date Incident Signed Off', IncidentFieldType.text),
  ]),
];

const List<String> yesNoOptions = ['yes', 'no'];




String titleCaseWords(String s) => s
    .split('_')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');


String displayFieldValue(IncidentFieldSpec spec, String? raw) {
  if (raw == null || raw.trim().isEmpty) return 'Not recorded';
  switch (spec.type) {
    case IncidentFieldType.dropdownYesNo:
      return raw == 'yes' ? 'Yes' : 'No';
    case IncidentFieldType.dropdownIncidentType:
      return titleCaseWords(raw);
    case IncidentFieldType.text:
    case IncidentFieldType.multiline:
    case IncidentFieldType.dropdownCategory:
    case IncidentFieldType.dropdownBodyPart:
      return raw;
  }
}
