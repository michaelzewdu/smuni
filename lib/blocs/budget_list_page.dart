import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';

// EVENTS

abstract class BudgetsListBlocEvent {
  const BudgetsListBlocEvent();
}

class LoadBudgetsFilter {
  final bool includeArchvied;
  final bool includeActive;
  const LoadBudgetsFilter(
      {this.includeActive = true, this.includeArchvied = false});

  @override
  String toString() =>
      "${runtimeType.toString()} { includeActive: $includeActive, includeArchvied: $includeArchvied, }";
}

class LoadBudgets extends BudgetsListBlocEvent {
  final LoadBudgetsFilter filter;
  const LoadBudgets({this.filter = const LoadBudgetsFilter()});
  @override
  String toString() => "${runtimeType.toString()} { filter: $filter, }";
}

/* class DeleteBudget extends BudgetsListBlocEvent {
  final String id;
  DeleteBudget(this.id);

  @override
  String toString() => "${runtimeType.toString()} { id: $id,  }";
} */

// STATE

abstract class BudgetListPageBlocState {
  const BudgetListPageBlocState();
}

class BudgetsLoading extends BudgetListPageBlocState {
  final LoadBudgetsFilter filterUsed;
  BudgetsLoading({required this.filterUsed}) : super();

  @override
  String toString() => "${runtimeType.toString()} {  filterUsed: $filterUsed }";
}

class BudgetsLoadSuccess extends BudgetListPageBlocState {
  final LoadBudgetsFilter filterUsed;
  final Map<String, Budget> items;

  BudgetsLoadSuccess(this.items, {required this.filterUsed}) : super();

  @override
  String toString() =>
      "${runtimeType.toString()} { items: $items, filterUsed: $filterUsed }";
}

// BLOC

class BudgetListPageBloc
    extends Bloc<BudgetsListBlocEvent, BudgetListPageBlocState> {
  BudgetRepository repo;
  BudgetListPageBloc(
    this.repo, [
    LoadBudgetsFilter initialFilter = const LoadBudgetsFilter(),
  ]) : super(BudgetsLoading(filterUsed: initialFilter)) {
    on<LoadBudgets>(streamToEmitterAdapter(_handleLoadBudge));
    // on<DeleteBudget>(streamToEmitterAdapter(_handleDeleteBudget));

    repo.changedItems.listen((ids) {
      final current = state;
      if (current is BudgetsLoading) {
        add(LoadBudgets(filter: current.filterUsed));
      } else if (current is BudgetsLoadSuccess) {
        add(LoadBudgets(filter: current.filterUsed));
      } else {
        throw Exception("unhandled type");
      }
    });
    add(LoadBudgets(filter: initialFilter));
  }

  Stream<BudgetListPageBlocState> _handleLoadBudge(LoadBudgets event) async* {
    yield BudgetsLoading(filterUsed: event.filter);
    final items = await repo.getItems();
    items.removeWhere(
      event.filter.includeActive && event.filter.includeArchvied
          // inlclude all
          ? (key, value) => false
          // include only archived
          : event.filter.includeArchvied
              ? (key, value) => !value.isArchived
              // default: include only active
              : (key, value) => value.isArchived,
    );
    yield BudgetsLoadSuccess(items, filterUsed: event.filter);
  }

  /*  Stream<BudgetListPageBlocState> _handleDeleteBudget(
      DeleteBudget event) async* {
    // TODO: plugin refresher
    final current = state;
    if (current is BudgetsLoadSuccess) {
      await repo.removeItem(event.id);
      current.items.remove(event.id);
      add(LoadBudgets(filter: current.filterUsed));
    } else if (current is BudgetsLoading) {
      await Future.delayed(const Duration(milliseconds: 500));
      add(event);
    }
  } */
}
