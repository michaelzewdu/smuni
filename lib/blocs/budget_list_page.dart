import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';

// EVENTS

abstract class BudgetsListBlocEvent {
  const BudgetsListBlocEvent();
}

class LoadBudgets extends BudgetsListBlocEvent {
  const LoadBudgets();
}

class DeleteBudget extends BudgetsListBlocEvent {
  final String id;
  DeleteBudget(this.id);

  @override
  String toString() => "${runtimeType.toString()} { id: $id,  }";
}

// STATE

abstract class BudgetListPageBlocState {
  const BudgetListPageBlocState();
}

class BudgetsLoading extends BudgetListPageBlocState {
  BudgetsLoading() : super();
}

class BudgetsLoadSuccess extends BudgetListPageBlocState {
  final Map<String, Budget> items;

  BudgetsLoadSuccess(
    this.items,
  ) : super();

  @override
  String toString() => "${runtimeType.toString()} { items: $items, }";
}

// BLOC

class BudgetListPageBloc
    extends Bloc<BudgetsListBlocEvent, BudgetListPageBlocState> {
  BudgetRepository repo;
  BudgetListPageBloc(
    this.repo,
  ) : super(BudgetsLoading()) {
    on<LoadBudgets>(streamToEmitterAdapter(_handleLoadBudge));
    on<DeleteBudget>(streamToEmitterAdapter(_handleDeleteBudget));

    repo.changedItems.listen((ids) {
      add(LoadBudgets());
    });
    add(LoadBudgets());
  }

  Stream<BudgetListPageBlocState> _handleLoadBudge(event) async* {
    yield BudgetsLoadSuccess(await repo.getItems());
  }

  Stream<BudgetListPageBlocState> _handleDeleteBudget(
      DeleteBudget event) async* {
    final current = state;
    if (current is BudgetsLoadSuccess) {
      await repo.removeItem(event.id);
      current.items.remove(event.id);

      yield BudgetsLoadSuccess(
        current.items,
      );
    } else if (current is BudgetsLoading) {
      await Future.delayed(const Duration(milliseconds: 500));
      add(event);
    }
  }
}
