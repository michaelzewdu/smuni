import 'dart:async';
import 'dart:collection';

import 'package:bloc/bloc.dart';

import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';

// EVENTS

abstract class CategoriesBlocEvent {
  const CategoriesBlocEvent();
}

class LoadCategories extends CategoriesBlocEvent {
  const LoadCategories();
}

class UpdateCategory extends CategoriesBlocEvent {
  final Category update;
  UpdateCategory(this.update);
}

class CreateCategory extends CategoriesBlocEvent {
  final Category item;
  CreateCategory(this.item);
}

class DeleteCategory extends CategoriesBlocEvent {
  final String id;
  DeleteCategory(this.id);
}

// STATE

abstract class CategoriesBlocState {
  const CategoriesBlocState();
}

class CategoriesLoading extends CategoriesBlocState {}

class CategoriesLoadSuccess extends CategoriesBlocState {
  final Map<String, Category> items;

  CategoriesLoadSuccess(this.items);
}

// BLOC

class CategoriesBloc extends Bloc<CategoriesBlocEvent, CategoriesBlocState> {
  Repository<String, Category> repo;
  CategoriesBloc(this.repo) : super(CategoriesLoading());

  @override
  Stream<CategoriesBlocState> mapEventToState(
    CategoriesBlocEvent event,
  ) async* {
    if (event is LoadCategories) {
      // TODO:  load from fs
      yield CategoriesLoadSuccess(
        HashMap.fromIterable(
          await repo.getItems(),
          key: (i) => i.id,
          value: (i) => i,
        ),
      );
    } else if (event is UpdateCategory) {
      // TODO

      final current = state;
      if (current is CategoriesLoadSuccess) {
        await repo.setItem(event.update.id, event.update);
        current.items[event.update.id] = event.update;
        yield CategoriesLoadSuccess(current.items);
      } else if (current is CategoriesLoading) {
        await Future.delayed(const Duration(milliseconds: 500));
        add(event);
      }
    } else if (event is CreateCategory) {
      final current = state;
      if (current is CategoriesLoadSuccess) {
        // TODO
        final item = Category.from(
          event.item,
          id: "id-${event.item.createdAt.microsecondsSinceEpoch}",
        );
        await repo.setItem(item.id, item);
        current.items[item.id] = item;
        yield CategoriesLoadSuccess(current.items);
      } else if (current is CategoriesLoading) {
        await Future.delayed(const Duration(milliseconds: 500));
        add(event);
      }
    } else if (event is DeleteCategory) {
      final current = state;
      if (current is CategoriesLoadSuccess) {
        // TODO
        await repo.removeItem(event.id);
        current.items.remove(event.id);

        yield CategoriesLoadSuccess(current.items);
      } else if (current is CategoriesLoading) {
        await Future.delayed(const Duration(milliseconds: 500));
        add(event);
      }
    }
  }
}
