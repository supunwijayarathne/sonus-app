// Small text helpers (kept here so screens stay short).

/// "Good morning" / "Good afternoon" / "Good evening".
String greetingFor(DateTime time) {
  if (time.hour < 12) return 'Good morning';
  if (time.hour < 17) return 'Good afternoon';
  return 'Good evening';
}

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', //
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// "Today, 6:42 PM", "Yesterday, 9:05 AM" or "Mar 18, 9:05 AM".
String sessionTime(DateTime at, {DateTime? now}) {
  now ??= DateTime.now();
  final hour12 = at.hour % 12 == 0 ? 12 : at.hour % 12;
  final minute = at.minute.toString().padLeft(2, '0');
  final clock = '$hour12:$minute ${at.hour < 12 ? 'AM' : 'PM'}';

  final day = DateTime(at.year, at.month, at.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;

  if (diff == 0) return 'Today, $clock';
  if (diff == 1) return 'Yesterday, $clock';
  return '${_months[at.month - 1].substring(0, 3)} ${at.day}, $clock';
}

/// "March 2026" (history section headings).
String monthYear(DateTime at) => '${_months[at.month - 1]} ${at.year}';

/// 0:03 (audio lengths). Rounds up, so a 0.8 s clip shows 0:01, not 0:00.
String clockDuration(Duration d) {
  final total = (d.inMilliseconds / 1000).ceil();
  final seconds = (total % 60).toString().padLeft(2, '0');
  return '${total ~/ 60}:$seconds';
}

/// 2 -> "Two" (for short sentences; falls back to digits above ten).
String numberWord(int n) {
  const words = [
    'No', 'One', 'Two', 'Three', 'Four', 'Five', //
    'Six', 'Seven', 'Eight', 'Nine', 'Ten',
  ];
  return n >= 0 && n < words.length ? words[n] : '$n';
}

/// "1 word" / "5 words".
String plural(int count, String singular, [String? pluralForm]) {
  return '$count ${count == 1 ? singular : (pluralForm ?? '${singular}s')}';
}
