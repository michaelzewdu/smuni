import 'dart:async';
import 'dart:collection';

import 'package:bloc/bloc.dart';

import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';

// EVENTS

abstract class ExpensesBlocEvent {
  const ExpensesBlocEvent();
}

class LoadExpenses extends ExpensesBlocEvent {
  const LoadExpenses();
}

class UpdateExpense extends ExpensesBlocEvent {
  final Expense update;
  UpdateExpense(this.update);
}

// STATE

abstract class ExpensesBlocState {
  const ExpensesBlocState();
}

class ExpensesLoading extends ExpensesBlocState {}

class ExpensesLoadSuccess extends ExpensesBlocState {
  final Map<String, Expense> expenses;

  ExpensesLoadSuccess(this.expenses);
}

// BLOC

class ExpensesBloc extends Bloc<ExpensesBlocEvent, ExpensesBlocState> {
  ExpenseRepository repo;
  ExpensesBloc(this.repo) : super(ExpensesLoading());

  @override
  Stream<ExpensesBlocState> mapEventToState(
    ExpensesBlocEvent event,
  ) async* {
    if (event is UpdateExpense) {
      repo.setItem(event.update.id, event.update);
      final expenses = (state as ExpensesLoadSuccess).expenses;
      expenses[event.update.id] = event.update;
      yield ExpensesLoadSuccess(expenses);
    } else if (event is LoadExpenses) {
      // TODO:  load from fs
      yield ExpensesLoadSuccess(
        HashMap.fromIterable(
          await repo.getItems(),
          key: (i) => i.id,
          value: (i) => i,
        ),
      );
    }
  }
}
