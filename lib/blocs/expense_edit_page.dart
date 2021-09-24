import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';

// EVENTS

abstract class ExpenseEditPageBlocEvent {
  const ExpenseEditPageBlocEvent();
}

class LoadItem extends ExpenseEditPageBlocEvent {
  final String id;
  const LoadItem(this.id);
}

class ModifyItem extends ExpenseEditPageBlocEvent {
  final Expense modified;

  ModifyItem(this.modified);
}

class DiscardChanges extends ExpenseEditPageBlocEvent {
  const DiscardChanges();
}

class SaveChanges extends ExpenseEditPageBlocEvent {
  const SaveChanges();
}

// STATE

class ExpenseEditPageBlocState {
  const ExpenseEditPageBlocState();
}

class LoadingItem extends ExpenseEditPageBlocState {
  final String id;
  const LoadingItem(this.id);
}

class ItemNotFound extends ExpenseEditPageBlocState {
  final String id;
  const ItemNotFound(this.id);
}

class UnmodifiedEditState extends ExpenseEditPageBlocState {
  final Expense unmodified;

  UnmodifiedEditState({
    required this.unmodified,
  });
}

class ModifiedEditState extends UnmodifiedEditState {
  final Expense modified;

  ModifiedEditState({required Expense unmodified, required this.modified})
      : super(unmodified: unmodified);
}

// BLOC

class ExpenseEditPageBloc
    extends Bloc<ExpenseEditPageBlocEvent, ExpenseEditPageBlocState> {
  Repository<String, Expense> repo;
  ExpenseEditPageBloc(this.repo, String id) : super(LoadingItem(id)) {
    repo.changedItems.listen((ids) {
      if (ids[0] == id) {
        add(LoadItem(id));
      }
    });
    add(LoadItem(id));
  }

  ExpenseEditPageBloc.modified(this.repo, Expense item)
      : super(ModifiedEditState(modified: item, unmodified: item));

  Stream<ExpenseEditPageBlocState> _mapLoadItemEventToState(
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

  Stream<ExpenseEditPageBlocState> _mapModifyItemEventToState(
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

  Stream<ExpenseEditPageBlocState> _mapSaveChangesEventToState(
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

  Stream<ExpenseEditPageBlocState> _mapDiscardChangesEventToState(
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
  Stream<ExpenseEditPageBlocState> mapEventToState(
    ExpenseEditPageBlocEvent event,
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
