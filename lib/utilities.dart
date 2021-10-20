import 'dart:async';

import 'package:flutter/material.dart' as flutter;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

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
      startTime <= other.startTime && endTime >= other.endTime;

  bool containsTimestamp(DateTime other) {
    var msSinceEpoch = other.millisecondsSinceEpoch;
    return startTime <= msSinceEpoch && endTime >= msSinceEpoch;
  }

  bool overlaps(DateRange other) =>
      startTime <= other.endTime && endTime >= other.startTime;

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

enum FilterLevel { day, week, month, year, all, custom }

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
  final filters = <DateRange, DateRangeFilter>{};
  for (final timestamp in timestamps) {
    final dayRange = DateRange.dayRange(timestamp);
    if (filters.containsKey(dayRange)) {
      continue;
    }
    filters[dayRange] = DateRangeFilter(
      "${monthNames[timestamp.month]} ${timestamp.day}",
      dayRange,
      FilterLevel.day,
    );

    final weekRange = DateRange.weekRange(timestamp);
    filters[weekRange] = DateRangeFilter(
      "Week ${(timestamp.day / 7) + 1}",
      weekRange,
      FilterLevel.week,
    );

    final monthRange = DateRange.monthRange(timestamp);
    filters[monthRange] = DateRangeFilter(
      monthNames[timestamp.month],
      monthRange,
      FilterLevel.month,
    );

    final yearRange = DateRange.yearRange(timestamp);
    filters[yearRange] = DateRangeFilter(
      timestamp.year.toString(),
      yearRange,
      FilterLevel.year,
    );
  }
  return filters;
}

class TreeNode<T> {
  final TreeNode<T>? parent;
  final T item;
  final List<T> children;

  TreeNode(this.item, {required this.children, this.parent});
}

FutureOr<void> Function(Event, Emitter<State>)
    streamToEmitterAdapter<Event, State>(
  Stream<State> Function(Event) eventHandler,
) =>
        (event, emit) async {
          await for (final state in eventHandler(event)) {
            emit(state);
          }
        };

abstract class OperationException implements Exception {}

class TimeoutException implements OperationException {}

class RefreshException implements OperationException {
  final OperationException inner;

  RefreshException(this.inner);

  @override
  String toString() => "${runtimeType.toString()} { inner: $inner }";
}

class ConnectionException extends OperationException {
  final SocketException inner;

  ConnectionException(this.inner);

  @override
  String toString() => "${runtimeType.toString()} { inner: $inner }";
}

typedef OperationSuccessNotifier = void Function();
typedef OperationExceptionNotifier = void Function(OperationException error);
mixin StatusAwareEvent {
  OperationSuccessNotifier? onSuccess;
  OperationExceptionNotifier? onError;
}

FutureOr<void> Function(Event, Emitter<State>)
    streamToEmitterAdapterStatusAware<Event extends StatusAwareEvent, State>(
  Stream<State> Function(Event) eventHandler,
) =>
        (event, emit) async {
          try {
            await for (final state in eventHandler(event)) {
              emit(state);
            }
            event.onSuccess?.call();
          } on OperationException catch (err) {
            event.onError?.call(err);
          }
        };
