import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:smuni/blocs/categories.dart';

import 'package:smuni/models/models.dart';

// EVENTS

abstract class CategoryEditPageBlocEvent {
  const CategoryEditPageBlocEvent();
}

class ModifyItem extends CategoryEditPageBlocEvent {
  final Category modified;

  ModifyItem(this.modified);
}

class DiscardChanges extends CategoryEditPageBlocEvent {
  const DiscardChanges();
}

class SaveChanges extends CategoryEditPageBlocEvent {
  const SaveChanges();
}

// STATE

class CategoryEditPageBlocState {
  final Category unmodified;

  CategoryEditPageBlocState({
    required this.unmodified,
  });
}

class ModifiedEditState extends CategoryEditPageBlocState {
  final Category modified;

  ModifiedEditState({required Category unmodified, required this.modified})
      : super(unmodified: unmodified);
}

// BLOC

class CategoryEditPageBloc
    extends Bloc<CategoryEditPageBlocEvent, CategoryEditPageBlocState> {
  CategoriesBloc itemsBloc;
  CategoryEditPageBloc(this.itemsBloc, Category item)
      : super(CategoryEditPageBlocState(unmodified: item));

  CategoryEditPageBloc.modified(this.itemsBloc, Category item)
      : super(ModifiedEditState(modified: item, unmodified: item));

  @override
  Stream<CategoryEditPageBlocState> mapEventToState(
    CategoryEditPageBlocEvent event,
  ) async* {
    if (event is ModifyItem) {
      yield ModifiedEditState(
          modified: event.modified, unmodified: state.unmodified);
      return;
    } else if (event is SaveChanges) {
      final current = state;
      if (current is ModifiedEditState) {
        itemsBloc.add(UpdateCategory(current.modified));

        yield CategoryEditPageBlocState(unmodified: state.unmodified);
      }
      return;
    } else if (event is DiscardChanges) {
      yield CategoryEditPageBlocState(unmodified: state.unmodified);
      return;
    }
    throw new Exception("Unhandeled event.");
  }
}
