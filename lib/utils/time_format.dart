import 'package:intl/intl.dart';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// True when [d] carries no time-of-day (weekly TV dates, movie/album
/// release days) — those read as "all day" rather than "at 12:00 AM".
bool isAllDay(DateTime d) => d.hour == 0 && d.minute == 0 && d.second == 0;

/// Compact remaining time for the rail: "42m", "5h 12m", "4d", "7w".
String shortUntil(DateTime target, DateTime now) {
  final diff = target.difference(now);
  if (diff.isNegative) {
    return dateOnly(target) == dateOnly(now) ? 'Today' : 'Out';
  }
  if (diff.inMinutes < 60) return '${diff.inMinutes.clamp(1, 59)}m';
  if (diff.inHours < 24) return '${diff.inHours}h ${diff.inMinutes % 60}m';
  if (diff.inDays < 60) return '${diff.inDays}d';
  return '${(diff.inDays / 7).round()}w';
}

/// Group heading for the time rail. Near dates get a day name, further ones
/// collapse into their month.
String railBucket(DateTime target, DateTime now) {
  final today = dateOnly(now);
  final day = dateOnly(target);
  final days = day.difference(today).inDays;

  if (days <= 0) return now.hour >= 17 ? 'Tonight' : 'Today';
  if (days == 1) return 'Tomorrow';
  if (days < 7) return DateFormat('EEEE').format(target);
  if (target.year == now.year) return DateFormat('MMMM').format(target);
  return DateFormat('MMMM y').format(target);
}

/// "Thu 2 Oct, 9:00 PM", or just the day when there's no time component.
String whenLabel(DateTime d) {
  final day = DateFormat('EEE d MMM').format(d);
  return isAllDay(d) ? day : '$day, ${DateFormat.jm().format(d)}';
}
