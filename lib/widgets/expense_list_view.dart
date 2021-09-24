import 'package:flutter/material.dart';

import 'package:smuni/models/models.dart';
import 'package:smuni/screens/Expense/expense_details_page.dart';
import 'package:smuni/utilities.dart';

class ExpenseListView extends StatelessWidget {
  final Map<String, Expense> items;
  final void Function(DateRangeFilter) loadRange;
  final DateRangeFilter displayedRange;
  final Iterable<DateRangeFilter> allDateRanges;

  const ExpenseListView(
      {Key? key,
      required this.items,
      required this.loadRange,
      required this.displayedRange,
      required this.allDateRanges})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<DateRangeFilter> yearGroups = [],
        monthGroups = [],
        weekGroups = [],
        dayGroups = [];
    for (final filter in allDateRanges) {
      switch (filter.level) {
        case FilterLevel.Year:
          yearGroups.add(filter);
          break;
        case FilterLevel.Month:
          monthGroups.add(filter);
          break;
        case FilterLevel.Week:
          weekGroups.add(filter);
          break;
        case FilterLevel.Day:
          dayGroups.add(filter);
          break;
        case FilterLevel.All:
          throw Exception("Unreachable code reached.");
      }
    }

    final currentFilterLevel = displayedRange.level;
    /*List<DateRangeFilter>? visibleGroups;
    switch (currentFilterLevel) {
      case FilterLevel.Year:
        final yearRange = DateRange.monthRange(
          DateTime(
            _selectedYear,
          ),
        );
        visibleGroups = monthGroups
            .where(
              (e) => e.range.overlaps(yearRange),
            )
            .toList();
        break;
      case FilterLevel.Month:
      case FilterLevel.Day:
        final monthRange =
            DateRange.monthRange(DateTime(_selectedYear, _selectedMonth));
        visibleGroups = dayGroups
            .where(
              (e) => e.range.overlaps(monthRange),
            )
            .toList();
        break;
      case FilterLevel.Week:
        throw UnimplementedError();
      case FilterLevel.All:
        break;
    }*/
    return Column(children: [
      // Year tab bar: always visible
      Row(
        children: [
          // All expenses button
          Builder(builder: (context) {
            final range = DateRangeFilter("All", DateRange(), FilterLevel.All);
            return _tabButton("All", () => this.loadRange(range),
                displayedRange.range.contains(range.range));
          }),
          ...yearGroups.map(
            (e) => _tabButton(e.name, () => this.loadRange(e),
                displayedRange.range.contains(e.range)),
          ),
        ],
      ),
      // Month tab bar: only visible when year or lower selected
      if (currentFilterLevel == FilterLevel.Year ||
          currentFilterLevel == FilterLevel.Month ||
          currentFilterLevel == FilterLevel.Day)
        Builder(builder: (context) {
          final currentYearRange = DateRangeFilter(
              "All months",
              DateRange.yearRange(
                DateTime.fromMillisecondsSinceEpoch(
                    displayedRange.range.startTime),
              ),
              FilterLevel.Year);
          return Row(
            children: [
              // All expenses in current year button
              _tabButton("All", () => this.loadRange(currentYearRange),
                  displayedRange.range.contains(currentYearRange.range)),
              ...monthGroups
                  .where((e) => e.range.overlaps(currentYearRange.range))
                  .map((e) => _tabButton(e.name, () => this.loadRange(e),
                      displayedRange.range.contains(e.range))),
            ],
          );
        }),
      // Day tab bar
      if (currentFilterLevel == FilterLevel.Month ||
          currentFilterLevel == FilterLevel.Day)
        Row(
          children: [
            // All days in current month button
            Builder(builder: (context) {
              final range = DateRangeFilter(
                  "All days",
                  DateRange.monthRange(
                    DateTime.fromMillisecondsSinceEpoch(
                        displayedRange.range.startTime),
                  ),
                  FilterLevel.Month);
              return _tabButton("All", () => this.loadRange(range),
                  displayedRange.range.contains(range.range));
            }),
            ...dayGroups
                .where((e) => e.range.overlaps(displayedRange.range))
                .map((e) => _tabButton(
                      e.name.split(" ")[1],
                      () => this.loadRange(e),
                      displayedRange.range.contains(e.range),
                    )),
          ],
        ),
      Builder(builder: (context) {
        final keys = items.keys;
        return items.isNotEmpty
            ? ListView.builder(
                shrinkWrap: true,
                itemCount: keys.length,
                itemBuilder: (context, index) {
                  final item = items[keys.elementAt(index)]!;
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text(
                      "${monthNames[item.createdAt.month]} ${item.createdAt.day} ${item.createdAt.year}",
                    ),
                    trailing: Text(
                      "${item.amount.currency} ${item.amount.amount / 100}",
                    ),
                    onTap: () => Navigator.pushNamed(
                      context,
                      ExpenseDetailsPage.routeName,
                      arguments: item.id,
                    ),
                  );
                },
              )
            : Center(child: const Text("No expenses."));
      })
    ]);
  }

  Widget _tabButton(
    String text,
    void Function()? onPressed, [
    bool isSelected = false,
  ]) =>
      isSelected
          ? ElevatedButton(
              onPressed: onPressed,
              child: Text(
                text,
              ),
              style: ButtonStyle(),
            )
          : TextButton(
              onPressed: onPressed,
              child: Text(
                text,
              ),
              style: ButtonStyle(),
            );
}
