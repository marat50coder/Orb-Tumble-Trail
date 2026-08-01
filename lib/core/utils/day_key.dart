/// Canonical `yyyy-MM-dd` identifier used as the storage key for a single day.
class DayKey {
  const DayKey._();

  static String of(DateTime date) {
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  static DateTime parse(String key) {
    final List<String> parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static DateTime today() {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime normalize(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static int daysBetween(DateTime from, DateTime to) =>
      normalize(to).difference(normalize(from)).inDays;
}
