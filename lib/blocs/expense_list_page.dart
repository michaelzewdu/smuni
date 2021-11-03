import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

import 'auth.dart';

// EVENTS

abstract class ExpensesListBlocEvent {
  const ExpensesListBlocEvent();
}

class LoadExpenses extends ExpensesListBlocEvent {
  final DateRangeFilter range;
  final String? ofBudget;
  final String? ofCategory;
  const LoadExpenses(this.range, {this.ofBudget, this.ofCategory});

  @override
  String toString() =>
      "${runtimeType.toString()} { range: $range, ofBudget: $ofBudget , ofCategory: $ofCategory }";
}

class DeleteExpense extends ExpensesListBlocEvent {
  final String id;
  DeleteExpense(this.id);

  @override
  String toString() => "${runtimeType.toString()} { id: $id }";
}

// STATE

abstract class ExpenseListPageBlocState {
  final DateRangeFilter range;
  const ExpenseListPageBlocState(
    this.range,
  );
}

class ExpensesLoading extends ExpenseListPageBlocState {
  final String? ofBudget;
  final String? ofCategory;
  ExpensesLoading(
    DateRangeFilter range, [
    this.ofBudget,
    this.ofCategory,
  ]) : super(range);

  @override
  String toString() =>
      "${runtimeType.toString()} { range: $range, ofBudget: $ofBudget , ofCategory: $ofCategory }";
}

class ExpensesLoadSuccess extends ExpenseListPageBlocState {
  final String? ofBudget;
  final String? ofCategory;

  /// cache the category filters
  Map<DateRange, DateRangeFilter> dateRangeFilters;
  final Set<String>? categoryFilter;

  final Map<String, Expense> items;

  ExpensesLoadSuccess(
    this.items,
    DateRangeFilter range,
    this.dateRangeFilters, [
    this.ofBudget,
    this.ofCategory,
    this.categoryFilter,
  ]) : super(range);

  @override
  String toString() =>
      "${runtimeType.toString()} { range: $range, dateRangeFilters: $dateRangeFilters, budgetFilter: $ofBudget, categoryFilter: $categoryFilter, items: $items }";
}

// BLOC

class ExpenseListPageBloc
    extends Bloc<ExpensesListBlocEvent, ExpenseListPageBlocState> {
  final ExpenseRepository repo;
  final OfflineExpenseRepository offlineRepo;
  final BudgetRepository budgetRepo;
  final CategoryRepository categoryRepo;
  final AuthBloc authBloc;

  ExpenseListPageBloc(
    this.repo,
    this.offlineRepo,
    this.authBloc,
    this.budgetRepo,
    this.categoryRepo,
    DateRangeFilter initialRangeToLoad, [
    String? initialBudgetToLoad,
    String? initialCategoryToLoad,
  ]) : super(
          ExpensesLoading(
            initialRangeToLoad,
            initialBudgetToLoad,
            initialCategoryToLoad,
          ),
        ) {
    on<LoadExpenses>(streamToEmitterAdapter(_mapLoadExpensesEventToState));
    on<DeleteExpense>(streamToEmitterAdapter(_mapDeleteExpenseEventToState));

    repo.changedItems.listen(_changeItemsListener);
    offlineRepo.changedItems.listen(_changeItemsListener);

    add(LoadExpenses(
      initialRangeToLoad,
      ofBudget: initialBudgetToLoad,
      ofCategory: initialCategoryToLoad,
    ));
  }

  void _changeItemsListener(Set<String> ids) {
    final current = state;
    if (current is ExpensesLoadSuccess) {
      add(LoadExpenses(
        current.range,
        ofBudget: current.ofBudget,
        ofCategory: current.ofCategory,
      ));
    } else if (current is ExpensesLoading) {
      add(LoadExpenses(
        current.range,
        ofBudget: current.ofBudget,
        ofCategory: current.ofCategory,
      ));
    } else {
      throw Exception("Unhandled type.");
    }
  }

  Stream<ExpenseListPageBlocState> _mapDeleteExpenseEventToState(
    DeleteExpense event,
  ) async* {
    final current = state;
    if (current is ExpensesLoadSuccess) {
      try {
        final auth = authBloc.authSuccesState();
        await repo.removeItem(event.id, auth.username, auth.authToken);
      } catch (err) {
        if (err is SocketException || err is UnauthenticatedException) {
          // do it offline if not connected or authenticated
          await offlineRepo.removeItemOffline(
            event.id,
          );
        } else {
          rethrow;
        }
      }
      current.items.remove(event.id);
      final dateRangeFilters = await repo.getDateRangeFilters(
        ofCategories: current.categoryFilter,
      );
      yield ExpensesLoadSuccess(
        current.items,
        current.range,
        dateRangeFilters,
        current.ofBudget,
        current.ofCategory,
        current.categoryFilter,
      );
    } else if (current is ExpensesLoading) {
      await Future.delayed(const Duration(milliseconds: 500));
      add(event);
      return;
    }
  }

  Stream<ExpenseListPageBlocState> _mapLoadExpensesEventToState(
    LoadExpenses event,
  ) async* {
    Set<String>? catFilter;
    final ofCategory = event.ofCategory;
    if (ofCategory != null) {
      final tree = (await categoryRepo.getCategoryDescendantsTree(ofCategory));
      if (tree == null) throw Exception("category not found");
      catFilter = tree.toSet();
    }

    final budgetFilter = event.ofBudget != null ? {event.ofBudget!} : null;

    final items = await repo.getItemsInRange(
      event.range.range,
      ofBudgets: budgetFilter,
      ofCategories: catFilter,
    );
    final dateRangeFilters = await repo.getDateRangeFilters(
      ofCategories: catFilter,
      ofBudgets: budgetFilter,
    );
    yield ExpensesLoadSuccess(
      {for (final item in items) item.id: item},
      event.range,
      dateRangeFilters,
      event.ofBudget,
      event.ofCategory,
      catFilter,
    );
  }
}
