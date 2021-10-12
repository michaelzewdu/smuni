import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';

// EVENTS

abstract class CategoriesListBlocEvent {
  const CategoriesListBlocEvent();
}

class LoadCategories extends CategoriesListBlocEvent {
  const LoadCategories();
}

class DeleteCategory extends CategoriesListBlocEvent {
  final String id;
  DeleteCategory(this.id);

  @override
  String toString() => "${runtimeType.toString()} { id: $id,  }";
}

// STATE

abstract class CategoryListPageBlocState {
  const CategoryListPageBlocState();
}

class CategoriesLoading extends CategoryListPageBlocState {
  CategoriesLoading() : super();
}

class CategoriesLoadSuccess extends CategoryListPageBlocState {
  final Map<String, Category> items;
  final Map<String, TreeNode<String>> ancestryGraph;

  CategoriesLoadSuccess(
    this.items,
    this.ancestryGraph,
  ) : super();

  @override
  String toString() =>
      "${runtimeType.toString()} { items: $items, ancestryGraph: $ancestryGraph, }";
}

// BLOC

class CategoryListPageBloc
    extends Bloc<CategoriesListBlocEvent, CategoryListPageBlocState> {
  CategoryRepository repo;
  CategoryListPageBloc(
    this.repo,
  ) : super(CategoriesLoading()) {
    on<LoadCategories>(streamToEmitterAdapter(_handleLoadCategories));
    on<DeleteCategory>(streamToEmitterAdapter(_handleDeleteCategory));

    repo.changedItems.listen((ids) {
      add(LoadCategories());
    });
    add(LoadCategories());
  }

  Stream<CategoryListPageBlocState> _handleDeleteCategory(
      DeleteCategory event) async* {
    final current = state;
    if (current is CategoriesLoadSuccess) {
      await repo.removeItem(event.id);
      current.items.remove(event.id);
      yield CategoriesLoadSuccess(current.items, await repo.ancestryGraph);
    } else if (current is CategoriesLoading) {
      await Future.delayed(const Duration(milliseconds: 500));
      add(event);
    }
  }

  Stream<CategoryListPageBlocState> _handleLoadCategories(
      LoadCategories event) async* {
    yield CategoriesLoadSuccess(
      await repo.getItems(),
      await repo.ancestryGraph,
    );
  }
}
