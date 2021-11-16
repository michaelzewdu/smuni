import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/utilities.dart';

import '../constants.dart';

class ExpenseListView extends StatefulWidget {
  final bool showCategoryDetail;
  final bool showBudgetDetail;

  final Map<String, Expense> items;
  final Map<String, Budget> allBudgets;
  final Map<String, Category> allCategories;
  final void Function(DateRangeFilter) loadRange;
  final DateRangeFilter displayedRange;
  final Iterable<DateRangeFilter> allDateRanges;

  /// These ranges will show up on their own filter group line. One button for each
  /// range.
  final List<DateRangeFilter>? unbucketedRanges;
  final bool dense;
  final FutureOr<void> Function(String)? onDelete;
  final FutureOr<void> Function(String)? onEdit;
  final List<DateRangeFilter> yearGroups = [],
      monthGroups = [],
      weekGroups = [],
      dayGroups = [];

  ExpenseListView({
    Key? key,
    required this.items,
    required this.allBudgets,
    required this.allCategories,
    required this.loadRange,
    required this.displayedRange,
    required this.allDateRanges,
    this.dense = false,
    this.onDelete,
    this.onEdit,
    this.unbucketedRanges,
    this.showCategoryDetail = true,
    this.showBudgetDetail = true,
  }) : super(key: key) {
    for (final filter in allDateRanges) {
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
          dayGroups.add(
            DateRangeFilter(
                filter.name.split(" ")[1], filter.range, filter.level),
          );
          break;
        case FilterLevel.all:
        case FilterLevel.custom:
          throw Exception("Unreachable code reached.");
      }
    }
  }

  @override
  State<ExpenseListView> createState() => _ExpenseListViewState();

  static Widget buttonChip(
    String text, {
    bool isSelected = true,
    bool isIncluded = true,
    FutureOr<void> Function()? onPressed,
  }) =>
      isSelected
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: onPressed,
                child: Text(text, style: TextStyle(color: semuni500)),
                style: ElevatedButton.styleFrom(
                  primary: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      side: BorderSide(color: semuni500),
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            )
          : isIncluded
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                      onPressed: onPressed,
                      child: Text(text, style: TextStyle(color: semuni500))),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                      onPressed: onPressed,
                      child: Text(text, style: TextStyle(color: Colors.grey))),
                );
}

class _ExpenseListViewState extends State<ExpenseListView> {
  String? _selectedItem;

  @override
  Widget build(BuildContext context) {
    final currentFilterLevel = widget.displayedRange.level;

    return Column(children: [
      if (widget.unbucketedRanges != null)
        Container(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // All expenses button
              Builder(builder: (context) {
                final range =
                    DateRangeFilter("All", DateRange(), FilterLevel.all);
                return _tabButton(range);
              }),
              ...widget.unbucketedRanges!.map(_tabButton),
            ],
          ),
        ),
      //Year tab bar: always visible
      Container(
        height: 50,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            // All expenses button
            Builder(builder: (context) {
              final range =
                  DateRangeFilter("All Years", DateRange(), FilterLevel.all);
              return _tabButton(range);
            }),
            ...widget.yearGroups.map(_tabButton),
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
                _tabButton(currentYearRange),
                ...widget.monthGroups
                    .where((e) => e.range.overlaps(currentYearRange.range))
                    .map(_tabButton),
              ],
            ),
          );
        }),
      // Day tab bar
      if (currentFilterLevel == FilterLevel.month ||
          currentFilterLevel == FilterLevel.day)
        Builder(builder: (context) {
          // All days in current month button
          final currentMonthRange = DateRangeFilter(
              "All days",
              DateRange.monthRange(
                DateTime.fromMillisecondsSinceEpoch(
                    widget.displayedRange.range.startTime),
              ),
              FilterLevel.month);
          return Container(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _tabButton(currentMonthRange),
                ...widget.dayGroups
                    .where((e) => e.range.overlaps(currentMonthRange.range))
                    .map(_tabButton),
              ],
            ),
          );
        }),
      widget.items.isNotEmpty
          ? _expenseListView(context)
          : const Center(
              child: Text(
                'Ooops, looks like you didn\'t add any expenses mate.',
              ),
            ),
    ]);
  }

  Widget _tabButton(DateRangeFilter range
          /* String text,
    void Function()? onPressed,
     [
    bool isSelected = false,
    bool isIn = false,] */
          ) =>
      ExpenseListView.buttonChip(
        range.name,
        isSelected: widget.displayedRange.range == range.range,
        onPressed: () => widget.loadRange(range),
        isIncluded: widget.displayedRange.range.contains(range.range),
      );

  Widget _expenseListView(BuildContext context) {
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
      children: keys.map((k) => widget.items[k]!).map<ExpansionPanel>((item) {
        final budget = widget.allBudgets[item.budgetId]!;
        final category = widget.allCategories[item.categoryId]!;

        return ExpansionPanel(
          canTapOnHeader: true,
          headerBuilder: (BuildContext context, bool isExpanded) => ListTile(
            title: Text(
              item.name,
              textScaleFactor: 1.25,
            ),
            dense: widget.dense,
            trailing: Text(
              "${item.amount.currency} ${item.amount.amount / 100}",
            ),
            subtitle: Text(
              '${monthNames[item.timestamp.month]} ${item.timestamp.day} ${item.timestamp.year}',
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ListTile(
                    dense: true,
                    title: Text(
                      '${monthNames[item.createdAt.month]} ${item.createdAt.day} ${item.createdAt.year}',
                    )),
                if (widget.showBudgetDetail)
                  ListTile(
                    dense: true,
                    leading: Text("Budget   "),
                    title: Text(
                      budget.name,
                    ),
                    subtitle: budget.isArchived
                        ? const Text(
                            "In Trash",
                            style: TextStyle(color: Colors.red),
                          )
                        : null,
                    trailing: Text(
                      "${budget.allocatedAmount.currency} ${budget.allocatedAmount.amount / 100}",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                if (widget.showCategoryDetail)
                  ListTile(
                    dense: true,
                    leading: Text("Category"),
                    title: Text(category.name),
                    subtitle: category.isArchived
                        ? const Text(
                            "In Trash",
                            style: TextStyle(color: Colors.red),
                          )
                        : null,
                    trailing: category.tags.isNotEmpty
                        ? Text(
                            category.tags.map((e) => "#$e").toList().join(" "),
                            style: TextStyle(color: Colors.grey),
                          )
                        : null,
                  ),
                if (widget.onEdit != null || widget.onDelete != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (widget.onEdit != null)
                        Center(
                          child: TextButton.icon(
                              onPressed: () => widget.onEdit?.call(item.id),
                              label: Text("Edit"),
                              icon: Icon(Icons.edit)),
                        ),
                      if (widget.onDelete != null)
                        TextButton.icon(
                            onPressed: () => widget.onDelete?.call(item.id),
                            label: Text("Delete"),
                            icon: Icon(Icons.delete))
                    ],
                  ),
              ],
            ),
          ),
          isExpanded: item.id == _selectedItem,
        );
      }).toList(),
    );
  }
}
