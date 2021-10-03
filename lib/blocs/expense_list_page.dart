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
  final String? ofBudget;
  final String? ofCategory;
  const LoadExpenses(this.range, {this.ofBudget, this.ofCategory});

  @override
  String toString() =>
      "${this.runtimeType.toString()} { range: $range, ofBudget: $ofBudget , ofCategory: $ofCategory }";
}

class DeleteExpense extends ExpensesListBlocEvent {
  final String id;
  DeleteExpense(this.id);

  @override
  String toString() => "${this.runtimeType.toString()} { id: $id }";
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
      "${this.runtimeType.toString()} { range: $range, ofBudget: $ofBudget , ofCategory: $ofCategory }";
}

class ExpensesLoadSuccess extends ExpenseListPageBlocState {
  Map<DateRange, DateRangeFilter> dateRangeFilters;
  final String? budgetFilter;
  final Set<String>? categoryFilter;
  final Map<String, Expense> items;

  ExpensesLoadSuccess(
    this.items,
    DateRangeFilter range,
    this.dateRangeFilters, [
    this.budgetFilter,
    this.categoryFilter,
  ]) : super(range);

  @override
  String toString() =>
      "${this.runtimeType.toString()} { range: $range, dateRangeFilters: $dateRangeFilters, budgetFilter: $budgetFilter, categoryFilter: $categoryFilter, items: $items }";
}

// BLOC

class ExpenseListPageBloc
    extends Bloc<ExpensesListBlocEvent, ExpenseListPageBlocState> {
  ExpenseRepository repo;
  BudgetRepository budgetRepo;
  CategoryRepository categoryRepo;
  ExpenseListPageBloc(
    this.repo,
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
    repo.changedItems.listen((ids) {
      add(LoadExpenses(
        const DateRangeFilter(
          "All",
          DateRange(),
          FilterLevel.All,
        ),
        ofBudget: initialBudgetToLoad,
        ofCategory: initialCategoryToLoad,
      ));
    });
    add(LoadExpenses(
      initialRangeToLoad,
      ofBudget: initialBudgetToLoad,
      ofCategory: initialCategoryToLoad,
    ));
  }

  @override
  Stream<ExpenseListPageBlocState> mapEventToState(
    ExpensesListBlocEvent event,
  ) async* {
    if (event is LoadExpenses) {
      Set<String>? catFilter;
      final ofCategory = event.ofCategory;
      if (ofCategory != null) {
        final tree =
            (await categoryRepo.getCategoryDescendantsTree(ofCategory));
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
      // TODO:  load from fs
      yield ExpensesLoadSuccess(
        HashMap.fromIterable(
          items,
          key: (i) => i.id,
          value: (i) => i,
        ),
        event.range,
        dateRangeFilters,
        event.ofBudget,
        catFilter,
      );
      return;
    } else if (event is DeleteExpense) {
      final current = state;
      if (current is ExpensesLoadSuccess) {
        // TODO
        await repo.removeItem(event.id);
        current.items.remove(event.id);
        final dateRangeFilters = await repo.getDateRangeFilters(
            ofCategories: current.categoryFilter);

        yield ExpensesLoadSuccess(
          current.items,
          current.range,
          dateRangeFilters,
          current.budgetFilter,
          current.categoryFilter,
        );
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
