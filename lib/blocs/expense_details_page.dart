import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:smuni/blocs/expenses.dart';

import 'package:smuni/models/models.dart';

// EVENTS

abstract class ExpenseDetailsPageBlocEvent {
  const ExpenseDetailsPageBlocEvent();
}

class StartEditing extends ExpenseDetailsPageBlocEvent {
  StartEditing();
}

class ModifyItem extends ExpenseDetailsPageBlocEvent {
  final Expense modified;

  ModifyItem(this.modified);
}

class DiscardChanges extends ExpenseDetailsPageBlocEvent {
  const DiscardChanges();
}

class SaveChanges extends ExpenseDetailsPageBlocEvent {
  const SaveChanges();
}

// STATE

abstract class ExpenseDetailsPageBlocState {
  const ExpenseDetailsPageBlocState();
}

class EditingExpense extends ExpenseDetailsPageBlocState {
  final Expense unmodified;
  final Expense modified;

  EditingExpense({required this.unmodified, required this.modified});
}

class ViewingExpense extends ExpenseDetailsPageBlocState {
  final Expense item;

  ViewingExpense(this.item);
}

// BLOC

class ExpenseDetailsPageBloc
    extends Bloc<ExpenseDetailsPageBlocEvent, ExpenseDetailsPageBlocState> {
  ExpensesBloc itemsBloc;
  ExpenseDetailsPageBloc(this.itemsBloc, Expense item)
      : super(ViewingExpense(item));

  @override
  Stream<ExpenseDetailsPageBlocState> mapEventToState(
    ExpenseDetailsPageBlocEvent event,
  ) async* {
    if (event is StartEditing) {
      final current = state;
      if (current is ViewingExpense) {
        yield EditingExpense(modified: current.item, unmodified: current.item);
      }
    } else if (event is ModifyItem) {
      final current = state;
      if (current is EditingExpense) {
        yield EditingExpense(
            modified: event.modified, unmodified: current.unmodified);
      } else if (current is ViewingExpense) {
        yield EditingExpense(
            modified: event.modified, unmodified: current.item);
      }
    } else if (event is SaveChanges) {
      final current = state;
      if (current is EditingExpense) {
        itemsBloc.add(UpdateExpense(current.modified));

        yield ViewingExpense(current.modified);
      }
    } else if (event is DiscardChanges) {
      final current = state;
      if (current is EditingExpense) {
        yield ViewingExpense(current.unmodified);
      }
    }
  }
}
