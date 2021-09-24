import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';

import 'expense_details_page.dart';
import 'expense_edit_page.dart';

class ExpenseListPage extends StatefulWidget {
  static const String routeName = "/expenseList";

  static Route route() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) => BlocProvider(
        create: (context) => ExpenseListPageBloc(
          context.read<ExpenseRepository>(),
          const DateRangeFilter(
            "All",
            DateRange(),
            FilterLevel.All,
          ),
        ),
        child: ExpenseListPage(),
      ),
    );
  }

  @override
  State<StatefulWidget> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
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
  Widget _list(BuildContext context, ExpensesLoadSuccess state) {
    List<DateRangeFilter> yearGroups = [],
        monthGroups = [],
        weekGroups = [],
        dayGroups = [];
    for (final filter in state.dateRangeFilters.values) {
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

    final currentFilterLevel = state.range.level;
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
            return _tabButton(
                "All",
                () => context
                    .read<ExpenseListPageBloc>()
                    .add(LoadExpenses(range)),
                state.range.range.contains(range.range));
          }),
          ...yearGroups.map(
            (e) => _tabButton(
                e.name,
                () => context.read<ExpenseListPageBloc>().add(LoadExpenses(e)),
                state.range.range.contains(e.range)),
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
                    state.range.range.startTime),
              ),
              FilterLevel.Year);
          return Row(
            children: [
              // All expenses in current year button
              _tabButton(
                  "All",
                  () => context
                      .read<ExpenseListPageBloc>()
                      .add(LoadExpenses(currentYearRange)),
                  state.range.range.contains(currentYearRange.range)),
              ...monthGroups
                  .where((e) => e.range.overlaps(currentYearRange.range))
                  .map((e) => _tabButton(
                      e.name,
                      () => context
                          .read<ExpenseListPageBloc>()
                          .add(LoadExpenses(e)),
                      state.range.range.contains(e.range))),
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
                        state.range.range.startTime),
                  ),
                  FilterLevel.Month);
              return _tabButton(
                  "All",
                  () => context
                      .read<ExpenseListPageBloc>()
                      .add(LoadExpenses(range)),
                  state.range.range.contains(range.range));
            }),
            ...dayGroups
                .where((e) => e.range.overlaps(state.range.range))
                .map((e) => _tabButton(
                      e.name,
                      () => context
                          .read<ExpenseListPageBloc>()
                          .add(LoadExpenses(e)),
                      state.range.range.contains(e.range),
                    )),
          ],
        ),
      Builder(
        builder: (context) {
          final items = state.items;
          final keys = items.keys;
          return Expanded(
            child: items.isNotEmpty
                ? ListView.builder(
                    itemCount: keys.length,
                    itemBuilder: (context, index) {
                      final item = items[keys.elementAt(index)]!;
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text(
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
                : Center(child: const Text("No expenses.")),
          );
        },
      )
    ]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text("Expenses"),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                ExpenseEditPage.routeName,
              ),
              child: const Text("New"),
            )
          ],
        ),
        body: BlocBuilder<ExpenseListPageBloc, ExpenseListPageBlocState>(
          builder: (context, state) {
            if (state is ExpensesLoadSuccess) {
              return _list(context, state);
            }
            return Center(child: CircularProgressIndicator.adaptive());
          },
        ),
      );
}
