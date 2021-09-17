import 'dart:async';
import 'dart:collection';

import 'package:bloc/bloc.dart';

import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';

// EVENTS

abstract class BudgetsBlocEvent {
  const BudgetsBlocEvent();
}

class LoadBudgets extends BudgetsBlocEvent {
  const LoadBudgets();
}

class UpdateBudget extends BudgetsBlocEvent {
  final Budget update;
  UpdateBudget(this.update);
}

class CreateBudget extends BudgetsBlocEvent {
  final Budget item;
  CreateBudget(this.item);
}

class DeleteBudget extends BudgetsBlocEvent {
  final String id;
  DeleteBudget(this.id);
}

// STATE

abstract class BudgetsBlocState {
  const BudgetsBlocState();
}

class BudgetsLoading extends BudgetsBlocState {}

class BudgetsLoadSuccess extends BudgetsBlocState {
  final Map<String, Budget> budgets;

  BudgetsLoadSuccess(this.budgets);
}

// BLOC

class BudgetsBloc extends Bloc<BudgetsBlocEvent, BudgetsBlocState> {
  Repository<String, Budget> repo;
  BudgetsBloc(this.repo) : super(BudgetsLoading());

  @override
  Stream<BudgetsBlocState> mapEventToState(
    BudgetsBlocEvent event,
  ) async* {
    if (event is LoadBudgets) {
      // TODO:  load from fs
      yield BudgetsLoadSuccess(
        HashMap.fromIterable(
          await repo.getItems(),
          key: (i) => i.id,
          value: (i) => i,
        ),
      );
    } else if (event is UpdateBudget) {
      // TODO

      final current = state;
      if (current is BudgetsLoadSuccess) {
        await repo.setItem(event.update.id, event.update);
        current.budgets[event.update.id] = event.update;
        yield BudgetsLoadSuccess(current.budgets);
      } else if (current is BudgetsLoading) {
        await Future.delayed(const Duration(milliseconds: 500));
        add(event);
      }
    } else if (event is CreateBudget) {
      final current = state;
      if (current is BudgetsLoadSuccess) {
        // TODO
        final item = Budget.from(
          event.item,
          id: "id-${event.item.createdAt.microsecondsSinceEpoch}",
        );
        await repo.setItem(item.id, item);
        current.budgets[item.id] = item;
        yield BudgetsLoadSuccess(current.budgets);
      } else if (current is BudgetsLoading) {
        await Future.delayed(const Duration(milliseconds: 500));
        add(event);
      }
    } else if (event is DeleteBudget) {
      final current = state;
      if (current is BudgetsLoadSuccess) {
        // TODO
        await repo.removeItem(event.id);
        current.budgets.remove(event.id);

        yield BudgetsLoadSuccess(current.budgets);
      } else if (current is BudgetsLoading) {
        await Future.delayed(const Duration(milliseconds: 500));
        add(event);
      }
    }
  }
}
