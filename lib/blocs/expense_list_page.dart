import 'dart:async';
import 'dart:collection';

import 'package:bloc/bloc.dart';

import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';

// EVENTS

abstract class ExpensesListBlocEvent {
  const ExpensesListBlocEvent();
}

class LoadExpenses extends ExpensesListBlocEvent {
  final DateRangeFilter range;
  const LoadExpenses(this.range);
}

class DeleteExpense extends ExpensesListBlocEvent {
  final String id;
  DeleteExpense(this.id);
}

// STATE

abstract class ExpenseListPageBlocState {
  final DateRangeFilter range;
  const ExpenseListPageBlocState(this.range);
}

class ExpensesLoading extends ExpenseListPageBlocState {
  ExpensesLoading(DateRangeFilter range) : super(range);
}

class ExpensesLoadSuccess extends ExpenseListPageBlocState {
  Map<DateRange, DateRangeFilter> dateRangeFilters;
  final Map<String, Expense> items;

  ExpensesLoadSuccess(this.items, DateRangeFilter range, this.dateRangeFilters)
      : super(range);
}

// BLOC

class ExpenseListPageBloc
    extends Bloc<ExpensesListBlocEvent, ExpenseListPageBlocState> {
  ExpenseRepository repo;
  ExpenseListPageBloc(this.repo, DateRangeFilter initialRangeToLoad)
      : super(
          ExpensesLoading(initialRangeToLoad),
        ) {
    repo.changedItems.listen((ids) {
      add(LoadExpenses(
        const DateRangeFilter(
          "All",
          DateRange(),
          FilterLevel.All,
        ),
      ));
    });
    add(LoadExpenses(initialRangeToLoad));
  }

  @override
  Stream<ExpenseListPageBlocState> mapEventToState(
    ExpensesListBlocEvent event,
  ) async* {
    if (event is LoadExpenses) {
      final items = await repo.getItemsInRange(event.range.range);
      final dateRangeFilters = await repo.dateRangeFilters;
      // TODO:  load from fs
      yield ExpensesLoadSuccess(
        HashMap.fromIterable(
          items,
          key: (i) => i.id,
          value: (i) => i,
        ),
        event.range,
        dateRangeFilters,
      );
      return;
    } else if (event is DeleteExpense) {
      final current = state;
      if (current is ExpensesLoadSuccess) {
        // TODO
        await repo.removeItem(event.id);
        current.items.remove(event.id);
        final dateRangeFilters = await repo.dateRangeFilters;

        yield ExpensesLoadSuccess(
            current.items, current.range, dateRangeFilters);
        return;
      } else if (current is ExpensesLoading) {
        await Future.delayed(const Duration(milliseconds: 500));
        add(event);
        return;
      }
    }
    throw Exception("Unhandled event");
  }
}
