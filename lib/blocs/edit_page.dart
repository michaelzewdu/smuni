import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';

// EVENTS

abstract class EditPageBlocEvent<Identifier, Item> {
  const EditPageBlocEvent();
}

class LoadItem<Identifier, Item> extends EditPageBlocEvent<Identifier, Item> {
  final Identifier id;
  const LoadItem(this.id);

  @override
  String toString() => "${runtimeType.toString()} { id: $id, }";
}

class ModifyItem<Identifier, Item> extends EditPageBlocEvent<Identifier, Item> {
  final Item modified;

  ModifyItem(this.modified);

  @override
  String toString() => "${runtimeType.toString()} { modified: $modified, }";
}

class DiscardChanges<Identifier, Item>
    extends EditPageBlocEvent<Identifier, Item> {
  const DiscardChanges();
}

class SaveChanges<Identifier, Item>
    extends EditPageBlocEvent<Identifier, Item> {
  const SaveChanges();
}

// STATE

class EditPageBlocState<Identifier, Item> {
  const EditPageBlocState();
}

class LoadingItem<Identifier, Item>
    extends EditPageBlocState<Identifier, Item> {
  final Identifier id;
  const LoadingItem(this.id);

  @override
  String toString() => "${runtimeType.toString()} { id: $id, }";
}

class ItemNotFound<Identifier, Item>
    extends EditPageBlocState<Identifier, Item> {
  final Identifier id;
  const ItemNotFound(this.id);

  @override
  String toString() => "${runtimeType.toString()} { id: $id, }";
}

class UnmodifiedEditState<Identifier, Item>
    extends EditPageBlocState<Identifier, Item> {
  final Identifier? id;
  final Item unmodified;

  UnmodifiedEditState({
    this.id,
    required this.unmodified,
  });

  @override
  String toString() =>
      "${runtimeType.toString()} { id: $unmodified, unmodified: $unmodified, }";
}

class ModifiedEditState<Identifier, Item>
    extends UnmodifiedEditState<Identifier, Item> {
  final Item modified;

  ModifiedEditState(
      {Identifier? id, required Item unmodified, required this.modified})
      : super(id: id, unmodified: unmodified);

  @override
  String toString() =>
      "${runtimeType.toString()} { id: $id, unmodified: $unmodified, modified: $modified, }";
}

// BLOC

class EditPageBloc<Identifier, Item> extends Bloc<
    EditPageBlocEvent<Identifier, Item>, EditPageBlocState<Identifier, Item>> {
  final bool isCreating;
  Repository<Identifier, Item, dynamic, dynamic> repo;

  EditPageBloc._(
    this.repo,
    this.isCreating,
    EditPageBlocState<Identifier, Item> initialState,
  ) : super(initialState) {
    on<LoadItem<Identifier, Item>>(
      streamToEmitterAdapter(_handleLoadItem),
    );
    on<ModifyItem<Identifier, Item>>(
      streamToEmitterAdapter(_handleModifyItem),
    );
    on<SaveChanges<Identifier, Item>>(
      streamToEmitterAdapter(_handleSaveChanges),
    );
    on<DiscardChanges<Identifier, Item>>(
      streamToEmitterAdapter(_handleDiscardChanges),
    );

    repo.changedItems.listen((ids) {
      final current = state;
      final id = current is UnmodifiedEditState<Identifier, Item>
          ? current.id
          : current is ItemNotFound<Identifier, Item>
              ? current.id
              : current is LoadingItem<Identifier, Item>
                  ? current.id
                  : null;
      if (id != null) {
        if (ids.contains(id)) {
          add(LoadItem(id));
        }
      }
    });
  }

  factory EditPageBloc.fromRepo(
          Repository<Identifier, Item, dynamic, dynamic> repo, Identifier id) =>
      EditPageBloc._(repo, false, LoadingItem(id))..add(LoadItem(id));

  EditPageBloc.modified(this.repo, Item item)
      : isCreating = true,
        super(
          ModifiedEditState(modified: item, unmodified: item),
        );

  Stream<EditPageBlocState<Identifier, Item>> _handleLoadItem(
    LoadItem event,
  ) async* {
    yield LoadingItem(event.id);
    final item = await repo.getItem(event.id);
    if (item != null) {
      yield UnmodifiedEditState(id: event.id, unmodified: item);
    } else {
      yield ItemNotFound(event.id);
    }
  }

  Stream<EditPageBlocState<Identifier, Item>> _handleModifyItem(
    ModifyItem event,
  ) async* {
    final current = state;
    if (current is UnmodifiedEditState<Identifier, Item>) {
      yield ModifiedEditState(
        id: current.id,
        modified: event.modified,
        unmodified: current.unmodified,
      );
    } else {
      throw Exception("Impossible event.");
    }
  }

  Stream<EditPageBlocState<Identifier, Item>> _handleSaveChanges(
    SaveChanges event,
  ) async* {
    final current = state;
    if (current is ModifiedEditState<Identifier, Item>) {
      if (isCreating) {
        final result = await repo.createItem(current.modified);
        yield UnmodifiedEditState(id: current.id, unmodified: result);
      } else {
        final result = await repo.updateItem(current.id!, current.modified);
        yield UnmodifiedEditState(id: current.id, unmodified: result);
      }
    }
  }

  Stream<EditPageBlocState<Identifier, Item>> _handleDiscardChanges(
    DiscardChanges event,
  ) async* {
    final current = state;
    if (current is ModifiedEditState<Identifier, Item>) {
      yield UnmodifiedEditState(id: current.id, unmodified: current.unmodified);
    }
  }
}
