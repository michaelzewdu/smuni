import 'dart:async';
import 'dart:collection';

class Pair<A, B> {
  final A a;
  final B b;

  const Pair(this.a, this.b);
}

class DateRange {
  final int startTime;
  final int endTime;

  const DateRange({this.startTime = 0, this.endTime = 8640000000000000});
  DateRange.usingDates({DateTime? startTime, DateTime? endTime})
      : this(
          startTime: startTime?.millisecondsSinceEpoch ?? 0,
          endTime: endTime?.millisecondsSinceEpoch ?? 8640000000000000,
        );
  DateRange.yearRange(DateTime timestamp)
      : this.usingDates(
          startTime: DateTime(timestamp.year),
          endTime: DateTime(timestamp.year + 1),
        );
  DateRange.weekRange(DateTime timestamp)
      : this.usingDates(
          startTime: DateTime(timestamp.year, timestamp.month,
              timestamp.day - timestamp.weekday),
          endTime: DateTime(
            timestamp.year,
            timestamp.month,
            timestamp.day - (7 - timestamp.weekday),
          ),
        );
  DateRange.monthRange(DateTime timestamp)
      : this.usingDates(
          startTime: DateTime(timestamp.year, timestamp.month),
          endTime: DateTime(timestamp.year, timestamp.month + 1),
        );
  DateRange.dayRange(DateTime timestamp)
      : this.usingDates(
          startTime: DateTime(timestamp.year, timestamp.month, timestamp.day),
          endTime: DateTime(
            timestamp.year,
            timestamp.month,
            timestamp.day + 1,
          ),
        );

  bool contains(DateRange other) =>
      this.startTime <= other.startTime && this.endTime >= other.endTime;

  bool containsTimestamp(DateTime other) {
    var msSinceEpoch = other.millisecondsSinceEpoch;
    return this.startTime <= msSinceEpoch && this.endTime >= msSinceEpoch;
  }

  bool overlaps(DateRange other) =>
      this.startTime <= other.endTime && this.endTime >= other.startTime;

  @override
  String toString() => "DateRange{ startTime: $startTime, endTime: $endTime }";

  @override
  bool operator ==(other) =>
      other is DateRange &&
      startTime == other.startTime &&
      endTime == other.endTime;

  @override
  int get hashCode => startTime ^ endTime;
}

enum FilterLevel { Day, Week, Month, Year, All }

class DateRangeFilter {
  final String name;
  final DateRange range;
  final FilterLevel level;

  const DateRangeFilter(this.name, this.range, this.level);
  @override
  String toString() {
    return "DateRangeFilter { name: $name, range: $range, level: $level }";
  }
}

// TODO: i10n
const List<String> monthNames = [
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "Jun",
  "Jul",
  "Aug",
  "Sep",
  "Oct",
  "Nov",
  "Dec"
];

Map<DateRange, DateRangeFilter> generateDateRangesFilters(
    Iterable<DateTime> timestamps) {
  Map<DateRange, DateRangeFilter> filters = new HashMap();
  for (final timestamp in timestamps) {
    final dayRange = DateRange.dayRange(timestamp);
    if (filters.containsKey(dayRange)) {
      continue;
    }
    filters[dayRange] = DateRangeFilter(
      "${monthNames[timestamp.month]} ${timestamp.day}",
      dayRange,
      FilterLevel.Day,
    );

    final weekRange = DateRange.weekRange(timestamp);
    filters[weekRange] = DateRangeFilter(
      "Week ${(timestamp.day / 7) + 1}",
      weekRange,
      FilterLevel.Week,
    );

    final monthRange = DateRange.monthRange(timestamp);
    filters[monthRange] = DateRangeFilter(
      monthNames[timestamp.month],
      monthRange,
      FilterLevel.Month,
    );

    final yearRange = DateRange.yearRange(timestamp);
    filters[yearRange] = DateRangeFilter(
      timestamp.year.toString(),
      yearRange,
      FilterLevel.Year,
    );
  }
  return filters;
}
