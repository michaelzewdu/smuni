import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';

// EVENTS

abstract class CategoriesListBlocEvent {
  const CategoriesListBlocEvent();
}

class LoadCategoriesFilter {
  final bool includeArchvied;
  final bool includeActive;
  const LoadCategoriesFilter(
      {this.includeActive = true, this.includeArchvied = false});

  @override
  String toString() =>
      "${runtimeType.toString()} { includeActive: $includeActive, includeArchvied: $includeArchvied, }";
}

class LoadCategories extends CategoriesListBlocEvent {
  final LoadCategoriesFilter filter;
  const LoadCategories({this.filter = const LoadCategoriesFilter()});
  @override
  String toString() => "${runtimeType.toString()} { filter: $filter, }";
}

/* class DeleteCategory extends CategoriesListBlocEvent {
  final String id;
  DeleteCategory(this.id);

  @override
  String toString() => "${runtimeType.toString()} { id: $id,  }";
}
 */
// STATE

abstract class CategoryListPageBlocState {
  const CategoryListPageBlocState();
}

class CategoriesLoading extends CategoryListPageBlocState {
  final LoadCategoriesFilter filterUsed;
  CategoriesLoading({required this.filterUsed}) : super();

  @override
  String toString() => "${runtimeType.toString()} {  filterUsed: $filterUsed }";
}

class CategoriesLoadSuccess extends CategoryListPageBlocState {
  final LoadCategoriesFilter filterUsed;
  final Map<String, Category> items;
  final Map<String, TreeNode<String>> ancestryGraph;

  CategoriesLoadSuccess(
    this.items, {
    required this.ancestryGraph,
    required this.filterUsed,
  }) : super();

  @override
  String toString() =>
      "${runtimeType.toString()} { items: $items, ancestryGraph: $ancestryGraph, filterUsed: $filterUsed, }";
}

// BLOC

class CategoryListPageBloc
    extends Bloc<CategoriesListBlocEvent, CategoryListPageBlocState> {
  final CategoryRepository repo;
  final OfflineCategoryRepository offlineRepo;

  CategoryListPageBloc(
    this.repo,
    this.offlineRepo, [
    LoadCategoriesFilter initialFilter = const LoadCategoriesFilter(),
  ]) : super(CategoriesLoading(filterUsed: initialFilter)) {
    on<LoadCategories>(streamToEmitterAdapter(_handleLoadCategories));
    // on<DeleteCategory>(streamToEmitterAdapter(_handleDeleteCategory));

    repo.changedItems.listen(_changeItemsListener);
    offlineRepo.changedItems.listen(_changeItemsListener);
    add(LoadCategories(filter: initialFilter));
  }

  void _changeItemsListener(Set<String> ids) {
    final current = state;
    if (current is CategoriesLoading) {
      add(LoadCategories(filter: current.filterUsed));
    } else if (current is CategoriesLoadSuccess) {
      add(LoadCategories(filter: current.filterUsed));
    } else {
      throw Exception("unhandled type");
    }
  }

/*   Stream<CategoryListPageBlocState> _handleDeleteCategory(
    DeleteCategory event,
  ) async* {
    // TODO: plugin refresher
    final current = state;
    if (current is CategoriesLoadSuccess) {
      await repo.removeItem(event.id);
      current.items.remove(event.id);
      yield CategoriesLoadSuccess(current.items,
          ancestryGraph: await repo.ancestryGraph,
          filterUsed: current.filterUsed);
    } else if (current is CategoriesLoading) {
      await Future.delayed(const Duration(milliseconds: 500));
      add(event);
    }
  }
 */
  Stream<CategoryListPageBlocState> _handleLoadCategories(
    LoadCategories event,
  ) async* {
    yield CategoriesLoading(filterUsed: event.filter);
    final allItems = await repo.getItems();

    final filteredAncestryGraph = CategoryRepositoryExt.calcAncestryTree(
      allItems.values
          .where(
            event.filter.includeActive && event.filter.includeArchvied
                ? (_) => true
                : event.filter.includeArchvied
                    ? (e) => e.isArchived
                    // default: include only active
                    : (e) => !e.isArchived,
          )
          .map((e) => e.id)
          .toSet(),
      allItems,
    );

    yield CategoriesLoadSuccess(
      allItems,
      filterUsed: event.filter,
      ancestryGraph: filteredAncestryGraph,
    );
  }
}
