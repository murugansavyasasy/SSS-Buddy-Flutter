// lib/utils/trip_date_utils.dart

const _monthMap = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
  'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
};

/// start_time string -> DateTime
/// Support: 2025-01-15 ..., 15-01-2025 ..., 15/01/2025 ..., 15-Jan-2025 ..., 15 January 2025
DateTime? parseTripDate(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;

  // MMM dd yyyy  (e.g. "Sep 29 2026 1:12PM", "September 29, 2026")
  var m = RegExp(r'([A-Za-z]{3})[A-Za-z]*\.?\s+(\d{1,2}),?\s+(\d{4})')
      .firstMatch(s);
  if (m != null) {
    final mon = _monthMap[m.group(1)!.toLowerCase()];
    if (mon != null) {
      return DateTime(
        int.parse(m.group(3)!),
        mon,
        int.parse(m.group(2)!),
      );
    }
  }

  // yyyy-MM-dd / yyyy/MM/dd
  m = RegExp(r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})').firstMatch(s);
  if (m != null) {
    return DateTime(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
  }

  // dd-MM-yyyy / dd/MM/yyyy
  m = RegExp(r'(\d{1,2})[-/](\d{1,2})[-/](\d{4})').firstMatch(s);
  if (m != null) {
    return DateTime(
      int.parse(m.group(3)!),
      int.parse(m.group(2)!),
      int.parse(m.group(1)!),
    );
  }

  // dd-MMM-yyyy / dd MMM yyyy / dd MMMM, yyyy
  m = RegExp(r'(\d{1,2})[\s\-/]+([A-Za-z]{3})[A-Za-z]*[\s\-/,]+(\d{4})')
      .firstMatch(s);
  if (m != null) {
    final mon = _monthMap[m.group(2)!.toLowerCase()];
    if (mon != null) {
      return DateTime(
        int.parse(m.group(3)!),
        mon,
        int.parse(m.group(1)!),
      );
    }
  }

  final iso = DateTime.tryParse(s);
  if (iso != null) return iso;

  print('⚠️ parseTripDate failed for: "$s"');
  return null;
}