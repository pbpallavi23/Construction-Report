class Formatters {
  const Formatters._();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String dateTime(String? isoUtc) {
    final dt = _parseLocal(isoUtc);
    if (dt == null) return isoUtc ?? '—';
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${_months[dt.month - 1]} ${dt.year}, $hh:$mm';
  }

  static String date(String? isoUtc) {
    final dt = _parseLocal(isoUtc);
    if (dt == null) return isoUtc ?? '—';
    return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
  }

  static String time(String? isoUtc) {
    final dt = _parseLocal(isoUtc);
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  static DateTime? _parseLocal(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso)?.toLocal();
  }
}
