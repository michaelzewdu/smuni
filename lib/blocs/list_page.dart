/* import 'dart:async';
import 'dart:collection';

import 'package:bloc/bloc.dart';

import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';

// EVENTS

abstract class ListBlocEvent<Identifier, Item, Filter> {
  const ListBlocEvent();
}

class LoadItems<Identifier, Item, Filter>
    extends ListBlocEvent<Identifier, Item, Filter> {
  final Filter filter;
  const LoadItems(this.filter);

  @override
  String toString() => "${runtimeType.toString()} { filter: $filter }";
}

class DeleteExpense<Identifier, Item, Filter>
    extends ListBlocEvent<Identifier, Item, Filter> {
  final Identifier id;
  DeleteExpense(this.id);

  @override
  String toString() => "${runtimeType.toString()} { id: $id }";
}

// STATE

abstract class ListPageBlocState<Identifier, Item, Filter> {
  const ListPageBlocState();
}

class ItemsLoading<Identifier, Item, Filter>
    extends ListPageBlocState<Identifier, Item, Filter> {
  final Filter filter;
  const ItemsLoading(this.filter);

  @override
  String toString() => "${runtimeType.toString()} { filter: $filter }";
}

class ItemsLoadSuccess<Identifier, Item, Filter>
    extends ListPageBlocState<Identifier, Item, Filter> {
  final Filter filter;
  final Map<String, Expense> items;

  ItemsLoadSuccess(this.items, this.filter);

  @override
  String toString() =>
      "${runtimeType.toString()} { items: $items, filter: $filter, }";
}

// BLOC

abstract class ListPageBloc<Identifier, Item, Filter> extends Bloc<
    ListBlocEvent<Identifier, Item, Filter>,
    ListPageBlocState<Identifier, Item, Filter>> {
  Repository<Identifier, Item, dynamic, dynamic> repo;
  ListPageBloc(this.repo, Filter initialFilterToLoad)
      : super(
          ItemsLoading(initialFilterToLoad),
        ) {
    on<LoadItems<Identifier, Item, Filter>>(
        streamToEmitterAdapter(_mapLoadItemsEventToState));
    on<DeleteExpense<Identifier, Item, Filter>>(
        streamToEmitterAdapter(_mapDeleteExpenseEventToState));

    repo.changedItems.listen((ids) {
      final current = state;
      if (current is ItemsLoadSuccess<Identifier, Item, Filter>) {
        add(LoadItems(current.filter));
      } else if (current is ItemsLoading<Identifier, Item, Filter>) {
        add(LoadItems(current.filter));
      } else {
        throw Exception("Unhandled type.");
      }
    });

    add(LoadItems(initialFilterToLoad));
  }

  Stream<ListPageBlocState<Identifier, Item, Filter>>
      _mapDeleteExpenseEventToState(
          DeleteExpense<Identifier, Item, Filter> event);

  Stream<ListPageBlocState<Identifier, Item, Filter>> _mapLoadItemsEventToState(
      LoadItems<Identifier, Item, Filter> event);
}

class ExpenseListPageBloc
    extends ListPageBloc<String, Expense, ExpenseListFilter> {
  ExpenseListPageBloc(Repository<String, Expense, dynamic, dynamic> repo,
      ExpenseListFilter initialFilterToLoad)
      : super(repo, initialFilterToLoad);

  @override
  Stream<ListPageBlocState<String, Expense, ExpenseListFilter>>
      _mapDeleteExpenseEventToState(
          DeleteExpense<String, Expense, ExpenseListFilter> event) async* {
    final current = state;
    if (current is ItemsLoadSuccess<String, Expense, ExpenseListFilter>) {
      await repo.removeItem(event.id);
      current.items.remove(event.id);
      final dateRangeFilters =
          await repo.getDateRangeFilters(ofCategories: current.categoryFilter);

      yield ItemsLoadSuccess(
        current.items,
        current.range,
        dateRangeFilters,
        current.ofBudget,
        current.ofCategory,
        current.categoryFilter,
      );
    } else if (current is ItemsLoading) {
      await Future.delayed(const Duration(milliseconds: 500));
      add(event);
      return;
    }
  }

  Stream<ListPageBlocState<String, Expense, ExpenseListFilter>>
      _mapLoadItemsEventToState(
          LoadItems<String, Expense, ExpenseListFilter> event) async* {
    final filter = getFilterForEvent(event);
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
    yield ItemsLoadSuccess(
      HashMap.fromIterable(
        items,
        key: (i) => i.id,
        value: (i) => i,
      ),
      event.range,
      dateRangeFilters,
      event.ofBudget,
      event.ofCategory,
      catFilter,
    );
  }
}

class ExpenseListFilter {
  final DateRangeFilter range;
  final String? ofBudget;
  final String? ofCategory;

  ExpenseListFilter({required this.range, this.ofBudget, this.ofCategory});
}

class CachedExpenseListFilter extends ExpenseListFilter {
  final Map<DateRange, DateRangeFilter> dateRangeFilters;
  final Set<String>? categoryFilter;

  CachedExpenseListFilter.from({
    required this.dateRangeFilters,
    this.categoryFilter,
    required DateRangeFilter range,
    String? ofBudget,
    String? ofCategory,
  }) : super(
          range: range,
          ofBudget: ofBudget,
          ofCategory: ofCategory,
        );
}
 */