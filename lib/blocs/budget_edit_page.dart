import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';

// EVENTS

abstract class BudgetEditPageBlocEvent {
  const BudgetEditPageBlocEvent();
}

class LoadItem extends BudgetEditPageBlocEvent {
  final String id;
  const LoadItem(this.id);

  @override
  String toString() => "${runtimeType.toString()} { id: $id, }";
}

class ModifyItem extends BudgetEditPageBlocEvent {
  final Budget modified;

  ModifyItem(this.modified);

  @override
  String toString() => "${runtimeType.toString()} { modified: $modified, }";
}

class DiscardChanges extends BudgetEditPageBlocEvent {
  const DiscardChanges();
}

class SaveChanges extends BudgetEditPageBlocEvent {
  const SaveChanges();
}

// STATE

class BudgetEditPageBlocState {
  const BudgetEditPageBlocState();
}

class LoadingItem extends BudgetEditPageBlocState {
  final String id;
  const LoadingItem(this.id);

  @override
  String toString() => "${runtimeType.toString()} { id: $id, }";
}

class ItemNotFound extends BudgetEditPageBlocState {
  final String id;
  const ItemNotFound(this.id);

  @override
  String toString() => "${runtimeType.toString()} { id: $id, }";
}

class UnmodifiedEditState extends BudgetEditPageBlocState {
  final Budget unmodified;

  UnmodifiedEditState({
    required this.unmodified,
  });

  @override
  String toString() => "${runtimeType.toString()} { unmodified: $unmodified, }";
}

class ModifiedEditState extends UnmodifiedEditState {
  final Budget modified;

  ModifiedEditState({required Budget unmodified, required this.modified})
      : super(unmodified: unmodified);

  @override
  String toString() =>
      "${runtimeType.toString()} { unmodified: $unmodified, modified: $modified, }";
}

// BLOC

class BudgetEditPageBloc
    extends Bloc<BudgetEditPageBlocEvent, BudgetEditPageBlocState> {
  Repository<String, Budget> repo;
  BudgetEditPageBloc(this.repo, String id) : super(LoadingItem(id)) {
    repo.changedItems.listen((ids) {
      if (ids[0] == id) {
        add(LoadItem(id));
      }
    });
    add(LoadItem(id));
  }

  BudgetEditPageBloc.modified(this.repo, Budget item)
      : super(ModifiedEditState(modified: item, unmodified: item));

  Stream<BudgetEditPageBlocState> _mapLoadItemEventToState(
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

  Stream<BudgetEditPageBlocState> _mapModifyItemEventToState(
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

  Stream<BudgetEditPageBlocState> _mapSaveChangesEventToState(
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

  Stream<BudgetEditPageBlocState> _mapDiscardChangesEventToState(
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
  Stream<BudgetEditPageBlocState> mapEventToState(
    BudgetEditPageBlocEvent event,
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
    throw Exception("Unhandeled event.");
  }
}
