import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';
import 'package:smuni/blocs/details_page.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/screens/Expense/expense_edit_page.dart';
import 'package:smuni/utilities.dart';

import '../constants.dart';

class ExpenseListView extends StatelessWidget {
  final Map<String, Expense> items;
  final void Function(DateRangeFilter) loadRange;
  final DateRangeFilter displayedRange;
  final Iterable<DateRangeFilter> allDateRanges;
  final bool dense;

  const ExpenseListView({
    Key? key,
    required this.items,
    required this.loadRange,
    required this.displayedRange,
    required this.allDateRanges,
    this.dense = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<DateRangeFilter> yearGroups = [],
        monthGroups = [],
        weekGroups = [],
        dayGroups = [];
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
          dayGroups.add(filter);
          break;
        case FilterLevel.all:
        case FilterLevel.custom:
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
    return ListView(children: [
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
              return _tabButton("All Years", () => loadRange(range),
                  displayedRange.range.contains(range.range));
            }),
            ...yearGroups.map(
              (e) => _tabButton(e.name, () => loadRange(e),
                  displayedRange.range.contains(e.range)),
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
                    displayedRange.range.startTime),
              ),
              FilterLevel.year);
          return Container(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // All expenses in current year button
                _tabButton("All months", () => loadRange(currentYearRange),
                    displayedRange.range.contains(currentYearRange.range)),
                ...monthGroups
                    .where((e) => e.range.overlaps(currentYearRange.range))
                    .map((e) => _tabButton(e.name, () => loadRange(e),
                        displayedRange.range.contains(e.range))),
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
                        displayedRange.range.startTime),
                  ),
                  FilterLevel.month);
              return _tabButton("All days", () => loadRange(range),
                  displayedRange.range.contains(range.range));
            }),
            ...dayGroups
                .where((e) => e.range.overlaps(displayedRange.range))
                .map((e) => _tabButton(
                      e.name.split(" ")[1],
                      () => loadRange(e),
                      displayedRange.range.contains(e.range),
                    )),
          ],
        ),
      Builder(builder: (context) {
        //final keys = items.keys;
        var expenses = [];
        items.forEach((key, value) {
          expenses.add(value);
        });
        //final values = items.map((key, value) => null)
        return expenses.isNotEmpty
            ? ExpensesExpandable(expenses: expenses)
            : Center(
                child: const Text(
                    'Ooops, looks like you didn\'t add any expenses mate.'));
        /*
        return items.isNotEmpty
            ? ListView.builder(
                shrinkWrap: true,
                itemCount: keys.length,
                itemBuilder: (context, index) {
                  final item = items[keys.elementAt(index)]!;
                  return Column(
                    children: [
                      ListTile(
                        dense: dense,
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
                      ),
                    ],
                  );
                },
              )
            : Center(child: const Text("No expenses."));

         */
      }),
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
                child: Text(
                  text,
                ),
                style: ButtonStyle(),
              ),
            );
}

class ExpensesExpandable extends StatefulWidget {
  const ExpensesExpandable({
    Key? key,
    required this.expenses,
  }) : super(key: key);

  final List expenses;

  @override
  State<ExpensesExpandable> createState() => _ExpensesExpandableState();
}

class _ExpensesExpandableState extends State<ExpensesExpandable> {
  // var isExpenseExpandedMap = new Map<String, bool>();
  String? _expandedItem;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ExpansionPanelList(
        dividerColor: Colors.transparent,
        animationDuration: Duration(seconds: 1),
        expansionCallback: (int index, bool isExpanded) {
          setState(() {
            final tappedId = widget.expenses[index].id;
            if (tappedId != _expandedItem) {
              _expandedItem = tappedId;
            } else {
              _expandedItem = null;
            }
          });
        },
        children: widget.expenses.map<ExpansionPanel>((e) {
          return ExpansionPanel(
            headerBuilder: (BuildContext context, bool isExpanded) {
              return //isExpanded
                  ListTile(
                title: Text(
                  e.name,
                  textScaleFactor: 1.25,
                ),
                subtitle: Text(
                    '${e.amount.amount.toString()} ${e.amount.currency.toString()}'),
                onTap: () {
                  /*
                  Navigator.pushNamed(
                    context,
                    ExpenseDetailsPage.routeName,
                    arguments: e.id,
                  );

                   */
                },
              );
              //  : ListTile(title: Text(e.name));
            },
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Text(' Updated on: ${e.updatedAt}'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Text('Created on: ${e.createdAt}'),
                      )
                    ],
                  ),
                  Column(
                    children: [
                      Center(
                        ///The buttons below are copied from Yoph's expense page and the delete button
                        ///uses the Expense details bloc(Which doesn't actually delete anything)
                        child: IconButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                ExpenseEditPage.routeName,
                                arguments: e.id,
                              );
                            },
                            icon: Icon(Icons.edit)),
                      ),
                      // FIXME: The delete button below doesn't actually delete

                      IconButton(
                          onPressed: () {
                            showDialog<bool?>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirm deletion'),
                                content: Text(
                                    'Are you sure you want to delete entry ${e.name}?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, true);
                                    },
                                    child: const Text('Confirm'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, false);
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                ],
                              ),
                            ).then((confirm) {
                              if (confirm != null && confirm) {
                                context
                                    .read<DetailsPageBloc<String, Expense>>()
                                    .add(DeleteItem());
                                Navigator.pop(context);
                              }
                            });
                          },
                          icon: Icon(Icons.delete))
                    ],
                  )
                ],
              ),
            ),
            isExpanded: e.id == _expandedItem,
          );
        }).toList(),
      ),
    );
  }
}
