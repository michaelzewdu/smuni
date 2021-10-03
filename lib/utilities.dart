import 'dart:collection';

import 'package:flutter/material.dart' as flutter;

class Pair<A, B> {
  final A a;
  final B b;

  const Pair(this.a, this.b);
}

class EnemeratedIterator<T> extends Iterator<Pair<int, T>> {
  int currentCount = -1;
  final Iterator<T> iterator;

  EnemeratedIterator(this.iterator);

  @override
  get current => Pair(currentCount, iterator.current);

  @override
  bool moveNext() {
    if (iterator.moveNext()) {
      currentCount += 1;
      return true;
    }
    return false;
  }
}

class EnemeratedIterable<T> extends Iterable<Pair<int, T>> {
  int currentCount = 0;
  final Iterable<T> iterable;

  EnemeratedIterable(this.iterable);

  @override
  // TODO: implement iterator
  Iterator<Pair<int, T>> get iterator => EnemeratedIterator(iterable.iterator);
}

extension IterableExt<T> on Iterable<T> {
  EnemeratedIterable<T> enumerated() => EnemeratedIterable(this);
}

class DateRange {
  final int startTime;
  final int endTime;

  const DateRange({this.startTime = 0, this.endTime = 8640000000000000});

  DateRange.fromFlutter(flutter.DateTimeRange from)
      : this(
          startTime: from.start.millisecondsSinceEpoch,
          endTime: from.end.millisecondsSinceEpoch,
        );
  DateRange.usingDates({DateTime? start, DateTime? end})
      : this(
          startTime: start?.millisecondsSinceEpoch ?? 0,
          endTime: end?.millisecondsSinceEpoch ?? 8640000000000000,
        );
  DateRange.yearRange(DateTime timestamp)
      : this.usingDates(
          start: DateTime(timestamp.year),
          end: DateTime(timestamp.year + 1),
        );
  DateRange.weekRange(DateTime timestamp)
      : this.usingDates(
          start: DateTime(timestamp.year, timestamp.month,
              timestamp.day - timestamp.weekday),
          end: DateTime(
            timestamp.year,
            timestamp.month,
            timestamp.day - (7 - timestamp.weekday),
          ),
        );
  DateRange.monthRange(DateTime timestamp)
      : this.usingDates(
          start: DateTime(timestamp.year, timestamp.month),
          end: DateTime(timestamp.year, timestamp.month + 1),
        );
  DateRange.dayRange(DateTime timestamp)
      : this.usingDates(
          start: DateTime(timestamp.year, timestamp.month, timestamp.day),
          end: DateTime(
            timestamp.year,
            timestamp.month,
            timestamp.day + 1,
          ),
        );

  DateTime get start => DateTime.fromMillisecondsSinceEpoch(startTime);
  DateTime get end => DateTime.fromMillisecondsSinceEpoch(endTime);
  Duration get duration => Duration(milliseconds: endTime - startTime);

  bool contains(DateRange other) =>
      this.startTime <= other.startTime && this.endTime >= other.endTime;

  bool containsTimestamp(DateTime other) {
    var msSinceEpoch = other.millisecondsSinceEpoch;
    return this.startTime <= msSinceEpoch && this.endTime >= msSinceEpoch;
  }

  bool overlaps(DateRange other) =>
      this.startTime <= other.endTime && this.endTime >= other.startTime;

  flutter.DateTimeRange toFlutter() =>
      flutter.DateTimeRange(start: start, end: end);

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

enum FilterLevel { Day, Week, Month, Year, All, Custom }

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
