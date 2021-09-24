import 'dart:async';
import 'dart:collection';

import 'package:bloc/bloc.dart';

import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';

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

  CategoriesLoadSuccess(
    this.items,
  ) : super();
}

// BLOC

class CategoryListPageBloc
    extends Bloc<CategoriesListBlocEvent, CategoryListPageBlocState> {
  CategoryRepository repo;
  CategoryListPageBloc(
    this.repo,
  ) : super(CategoriesLoading()) {
    repo.changedItems.listen((ids) {
      add(LoadCategories());
    });
    add(LoadCategories());
  }

  @override
  Stream<CategoryListPageBlocState> mapEventToState(
    CategoriesListBlocEvent event,
  ) async* {
    if (event is LoadCategories) {
      final items = await repo.getItems();

      // TODO:  load from fs
      yield CategoriesLoadSuccess(
        HashMap.fromIterable(
          items,
          key: (i) => i.id,
          value: (i) => i,
        ),
      );
      return;
    } else if (event is DeleteCategory) {
      final current = state;
      if (current is CategoriesLoadSuccess) {
        // TODO
        await repo.removeItem(event.id);
        current.items.remove(event.id);

        yield CategoriesLoadSuccess(current.items);
        return;
      } else if (current is CategoriesLoading) {
        await Future.delayed(const Duration(milliseconds: 500));
        add(event);
        return;
      }
    }
    throw Exception("Unhandled event");
  }
}
