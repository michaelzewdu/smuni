import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:smuni/blocs/expenses.dart';

import 'package:smuni/models/models.dart';

// EVENTS

abstract class ExpenseEditPageBlocEvent {
  const ExpenseEditPageBlocEvent();
}

class ModifyItem extends ExpenseEditPageBlocEvent {
  final Expense modified;

  ModifyItem(this.modified);
}

class DiscardChanges extends ExpenseEditPageBlocEvent {
  const DiscardChanges();
}

class SaveChanges extends ExpenseEditPageBlocEvent {
  const SaveChanges();
}

// STATE

class ExpenseEditPageBlocState {
  final Expense unmodified;

  ExpenseEditPageBlocState({
    required this.unmodified,
  });
}

class ModifiedEditState extends ExpenseEditPageBlocState {
  final Expense modified;

  ModifiedEditState({required Expense unmodified, required this.modified})
      : super(unmodified: unmodified);
}

// BLOC

class ExpenseEditPageBloc
    extends Bloc<ExpenseEditPageBlocEvent, ExpenseEditPageBlocState> {
  ExpensesBloc itemsBloc;
  ExpenseEditPageBloc(this.itemsBloc, Expense item)
      : super(ExpenseEditPageBlocState(unmodified: item));

  ExpenseEditPageBloc.modified(this.itemsBloc, Expense item)
      : super(ModifiedEditState(modified: item, unmodified: item));

  @override
  Stream<ExpenseEditPageBlocState> mapEventToState(
    ExpenseEditPageBlocEvent event,
  ) async* {
    if (event is ModifyItem) {
      yield ModifiedEditState(
          modified: event.modified, unmodified: state.unmodified);
    } else if (event is SaveChanges) {
      final current = state;
      if (current is ModifiedEditState) {
        itemsBloc.add(UpdateExpense(current.modified));

        yield ExpenseEditPageBlocState(unmodified: state.unmodified);
      }
    } else if (event is DiscardChanges) {
      yield ExpenseEditPageBlocState(unmodified: state.unmodified);
    }
  }
}
