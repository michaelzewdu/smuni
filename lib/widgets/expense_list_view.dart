import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smuni/blocs/details_page.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/screens/Expense/expense_edit_page.dart';
import 'package:smuni/utilities.dart';

import '../constants.dart';

class ExpenseListView extends StatefulWidget {
  final Map<String, Expense> items;
  final void Function(DateRangeFilter) loadRange;
  final DateRangeFilter displayedRange;
  final Iterable<DateRangeFilter> allDateRanges;
  final bool dense;
  final FutureOr<void> Function(String)? onDelete;
  final FutureOr<void> Function(String)? onEdit;

  const ExpenseListView({
    Key? key,
    required this.items,
    required this.loadRange,
    required this.displayedRange,
    required this.allDateRanges,
    this.dense = false,
    this.onDelete,
    this.onEdit,
  }) : super(key: key);

  @override
  State<ExpenseListView> createState() => _ExpenseListViewState();
}

class _ExpenseListViewState extends State<ExpenseListView> {
  String? _selectedItem;

  @override
  Widget build(BuildContext context) {
    List<DateRangeFilter> yearGroups = [],
        monthGroups = [],
        weekGroups = [],
        dayGroups = [];
    for (final filter in widget.allDateRanges) {
      switch (filter.level) {
        case FilterLevel.year:
          yearGroups.add(filter);
          break;
        case FilterLevel.month:
          monthGroups.add(filter);
          break;
        case FilterLevel.week:
          weekGroups.add(filter);
          break;
        case FilterLevel.day:
          dayGroups.add(filter);
          break;
        case FilterLevel.all:
        case FilterLevel.custom:
          throw Exception("Unreachable code reached.");
      }
    }

    final currentFilterLevel = widget.displayedRange.level;
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
      //Year tab bar: always visible
      Container(
        height: 50,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            // All expenses button
            Builder(builder: (context) {
              final range =
                  DateRangeFilter("All", DateRange(), FilterLevel.all);
              return _tabButton("All Years", () => widget.loadRange(range),
                  widget.displayedRange.range.contains(range.range));
            }),
            ...yearGroups.map(
              (e) => _tabButton(e.name, () => widget.loadRange(e),
                  widget.displayedRange.range.contains(e.range)),
            ),
          ],
        ),
      ),
      // Month tab bar: only visible when year or lower selected
      if (currentFilterLevel == FilterLevel.year ||
          currentFilterLevel == FilterLevel.month ||
          currentFilterLevel == FilterLevel.day)
        Builder(builder: (context) {
          final currentYearRange = DateRangeFilter(
              "All months",
              DateRange.yearRange(
                DateTime.fromMillisecondsSinceEpoch(
                    widget.displayedRange.range.startTime),
              ),
              FilterLevel.year);
          return Container(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // All expenses in current year button
                _tabButton(
                    "All months",
                    () => widget.loadRange(currentYearRange),
                    widget.displayedRange.range
                        .contains(currentYearRange.range)),
                ...monthGroups
                    .where((e) => e.range.overlaps(currentYearRange.range))
                    .map((e) => _tabButton(e.name, () => widget.loadRange(e),
                        widget.displayedRange.range.contains(e.range))),
              ],
            ),
          );
        }),
      // Day tab bar
      if (currentFilterLevel == FilterLevel.month ||
          currentFilterLevel == FilterLevel.day)
        Row(
          children: [
            // All days in current month button
            Builder(builder: (context) {
              final range = DateRangeFilter(
                  "All days",
                  DateRange.monthRange(
                    DateTime.fromMillisecondsSinceEpoch(
                        widget.displayedRange.range.startTime),
                  ),
                  FilterLevel.month);
              return _tabButton("All days", () => widget.loadRange(range),
                  widget.displayedRange.range.contains(range.range));
            }),
            ...dayGroups
                .where((e) => e.range.overlaps(widget.displayedRange.range))
                .map((e) => _tabButton(
                      e.name.split(" ")[1],
                      () => widget.loadRange(e),
                      widget.displayedRange.range.contains(e.range),
                    )),
          ],
        ),
      widget.items.isNotEmpty
          ? _expenseListView(context)
          : const Center(
              child: Text(
                'Ooops, looks like you didn\'t add any expenses mate.',
              ),
            ),
    ]);
  }

  Widget _tabButton(
    String text,
    void Function()? onPressed, [
    bool isSelected = false,
  ]) =>
      isSelected
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: onPressed,
                child: Text(
                  text,
                  style: TextStyle(color: semuni500),
                ),
                style: ElevatedButton.styleFrom(
                    primary: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        side: BorderSide(color: semuni500),
                        borderRadius: BorderRadius.circular(16))),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextButton(
                onPressed: onPressed,
                child: Text(text),
              ),
            );

  Widget _expenseListView(BuildContext context) => SingleChildScrollView(
        child: Builder(builder: (context) {
          final keys = widget.items.keys.toList();
          return ExpansionPanelList(
            dividerColor: Colors.transparent,
            expandedHeaderPadding: const EdgeInsets.symmetric(vertical: 2),
            animationDuration: Duration(milliseconds: 400),
            expansionCallback: (int index, bool isExpanded) {
              setState(() {
                final tappedId = widget.items[keys[index]]!.id;
                if (tappedId != _selectedItem) {
                  _selectedItem = tappedId;
                } else {
                  _selectedItem = null;
                }
              });
            },
            children: keys
                .map((k) => widget.items[k]!)
                .map<ExpansionPanel>((item) => ExpansionPanel(
                      canTapOnHeader: true,
                      headerBuilder: (BuildContext context, bool isExpanded) =>
                          ListTile(
                        title: Text(
                          item.name,
                          textScaleFactor: 1.25,
                        ),
                        dense: widget.dense,
                        trailing: Text(
                          "${item.amount.currency} ${item.amount.amount / 100}",
                        ),
                        subtitle: Text(
                          '${monthNames[item.createdAt.month]} ${item.createdAt.day} ${item.createdAt.year}',
                        ),
                      ),
                      body: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Text(
                                      '${monthNames[item.createdAt.month]} ${item.createdAt.day} ${item.createdAt.year}'),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Text(
                                      'TODO: show budget and category here'),
                                )
                              ],
                            ),
                            Column(
                              children: [
                                Center(
                                  ///The buttons below are copied from Yoph's expense page and the delete button
                                  ///uses the Expense details bloc(Which doesn't actually delete anything)
                                  child: IconButton(
                                      onPressed: () =>
                                          widget.onEdit?.call(item.id),
                                      icon: Icon(Icons.edit)),
                                ),
                                // FIXME: The delete button below doesn't actually delete

                                IconButton(
                                    onPressed: () =>
                                        widget.onDelete?.call(item.id),
                                    icon: Icon(Icons.delete))
                              ],
                            )
                          ],
                        ),
                      ),
                      isExpanded: item.id == _selectedItem,
                    ))
                .toList(),
          );
        }),
      );
}
