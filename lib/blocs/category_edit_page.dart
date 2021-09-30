import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';

// EVENTS

abstract class CategoryEditPageBlocEvent {
  const CategoryEditPageBlocEvent();
}

class LoadItem extends CategoryEditPageBlocEvent {
  final String id;
  const LoadItem(this.id);

  @override
  String toString() => "${this.runtimeType.toString()} { id: $id, }";
}

class ModifyItem extends CategoryEditPageBlocEvent {
  final Category modified;

  ModifyItem(this.modified);

  @override
  String toString() =>
      "${this.runtimeType.toString()} { modified: $modified, }";
}

class DiscardChanges extends CategoryEditPageBlocEvent {
  const DiscardChanges();
}

class SaveChanges extends CategoryEditPageBlocEvent {
  const SaveChanges();
}

// STATE

class CategoryEditPageBlocState {
  const CategoryEditPageBlocState();
}

class LoadingItem extends CategoryEditPageBlocState {
  final String id;
  const LoadingItem(this.id);

  @override
  String toString() => "${this.runtimeType.toString()} { id: $id, }";
}

class ItemNotFound extends CategoryEditPageBlocState {
  final String id;
  const ItemNotFound(this.id);

  @override
  String toString() => "${this.runtimeType.toString()} { id: $id, }";
}

class UnmodifiedEditState extends CategoryEditPageBlocState {
  final Category unmodified;

  UnmodifiedEditState({
    required this.unmodified,
  });

  @override
  String toString() =>
      "${this.runtimeType.toString()} { unmodified: $unmodified, }";
}

class ModifiedEditState extends UnmodifiedEditState {
  final Category modified;

  ModifiedEditState({required Category unmodified, required this.modified})
      : super(unmodified: unmodified);

  @override
  String toString() =>
      "${this.runtimeType.toString()} { unmodified: $unmodified, modified: $modified, }";
}

// BLOC

class CategoryEditPageBloc
    extends Bloc<CategoryEditPageBlocEvent, CategoryEditPageBlocState> {
  Repository<String, Category> repo;
  CategoryEditPageBloc(this.repo, String id) : super(LoadingItem(id)) {
    repo.changedItems.listen((ids) {
      if (ids[0] == id) {
        add(LoadItem(id));
      }
    });
    add(LoadItem(id));
  }

  CategoryEditPageBloc.modified(this.repo, Category item)
      : super(ModifiedEditState(modified: item, unmodified: item));

  Stream<CategoryEditPageBlocState> _mapLoadItemEventToState(
    LoadItem event,
  ) async* {
    yield LoadingItem(event.id);
    final item = await repo.getItem(event.id);
    if (item != null) {
      yield UnmodifiedEditState(unmodified: item);
      return;
    } else {
      yield ItemNotFound(event.id);
      return;
    }
  }

  Stream<CategoryEditPageBlocState> _mapModifyItemEventToState(
    ModifyItem event,
  ) async* {
    final current = state;
    if (current is UnmodifiedEditState) {
      yield ModifiedEditState(
          modified: event.modified, unmodified: current.unmodified);
      return;
    } else {
      throw Exception("Impossible event.");
    }
  }

  Stream<CategoryEditPageBlocState> _mapSaveChangesEventToState(
    SaveChanges event,
  ) async* {
    final current = state;
    if (current is ModifiedEditState) {
      // TODO
      await repo.setItem(current.modified.id, current.modified);
      yield UnmodifiedEditState(unmodified: current.modified);
    }
    return;
  }

  Stream<CategoryEditPageBlocState> _mapDiscardChangesEventToState(
    DiscardChanges event,
  ) async* {
    final current = state;
    if (current is ModifiedEditState) {
      yield UnmodifiedEditState(unmodified: current.unmodified);
      return;
    } else {
      return;
    }
  }

  @override
  Stream<CategoryEditPageBlocState> mapEventToState(
    CategoryEditPageBlocEvent event,
  ) {
    if (event is LoadItem) {
      return _mapLoadItemEventToState(event);
    } else if (event is ModifyItem) {
      return _mapModifyItemEventToState(event);
    } else if (event is SaveChanges) {
      return _mapSaveChangesEventToState(event);
    } else if (event is DiscardChanges) {
      return _mapDiscardChangesEventToState(event);
    }
    throw new Exception("Unhandeled event.");
  }
}
