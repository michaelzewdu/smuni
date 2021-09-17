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

class CreateExpense extends ExpensesBlocEvent {
  final Expense item;
  CreateExpense(this.item);
}

class DeleteExpense extends ExpensesBlocEvent {
  final String id;
  DeleteExpense(this.id);
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
  Repository<String, Expense> repo;
  ExpensesBloc(this.repo) : super(ExpensesLoading());

  @override
  Stream<ExpensesBlocState> mapEventToState(
    ExpensesBlocEvent event,
  ) async* {
    if (event is LoadExpenses) {
      // TODO:  load from fs
      yield ExpensesLoadSuccess(
        HashMap.fromIterable(
          await repo.getItems(),
          key: (i) => i.id,
          value: (i) => i,
        ),
      );
    } else if (event is UpdateExpense) {
      // TODO

      final current = state;
      if (current is ExpensesLoadSuccess) {
        await repo.setItem(event.update.id, event.update);
        current.expenses[event.update.id] = event.update;
        yield ExpensesLoadSuccess(current.expenses);
      } else if (current is ExpensesLoading) {
        await Future.delayed(const Duration(milliseconds: 500));
        add(event);
      }
    } else if (event is CreateExpense) {
      final current = state;
      if (current is ExpensesLoadSuccess) {
        // TODO
        final item = Expense.from(
          event.item,
          id: "id-${event.item.createdAt.microsecondsSinceEpoch}",
        );
        await repo.setItem(item.id, item);
        current.expenses[item.id] = item;
        yield ExpensesLoadSuccess(current.expenses);
      } else if (current is ExpensesLoading) {
        await Future.delayed(const Duration(milliseconds: 500));
        add(event);
      }
    } else if (event is DeleteExpense) {
      final current = state;
      if (current is ExpensesLoadSuccess) {
        // TODO
        await repo.removeItem(event.id);
        current.expenses.remove(event.id);

        yield ExpensesLoadSuccess(current.expenses);
      } else if (current is ExpensesLoading) {
        await Future.delayed(const Duration(milliseconds: 500));
        add(event);
      }
    }
  }
}
