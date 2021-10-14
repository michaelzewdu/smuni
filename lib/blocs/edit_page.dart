import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

// EVENTS

abstract class EditPageBlocEvent<Identifier, Item> {
  const EditPageBlocEvent();
}

class LoadItem<Identifier, Item> extends EditPageBlocEvent<Identifier, Item>
    with StatusAwareEvent {
  final Identifier id;
  LoadItem(
    this.id, {
    OperationSuccessNotifier? onSuccess,
    OperationExceptionNotifier? onError,
  }) {
    this.onSuccess = onSuccess;
    this.onError = onError;
  }

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

class SaveChanges<Identifier, Item> extends EditPageBlocEvent<Identifier, Item>
    with StatusAwareEvent {
  SaveChanges({
    OperationSuccessNotifier? onSuccess,
    OperationExceptionNotifier? onError,
  }) {
    this.onSuccess = onSuccess;
    this.onError = onError;
  }
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

class LoadSuccessEditState<Identifier, Item>
    extends EditPageBlocState<Identifier, Item> {
  final Identifier? id;
  final Item item;

  LoadSuccessEditState({
    this.id,
    required this.item,
  });

  @override
  String toString() =>
      "${runtimeType.toString()} { id: $item, unmodified: $item, }";
}

class ModifiedEditState<Identifier, Item>
    extends LoadSuccessEditState<Identifier, Item> {
  final Item unmodified;

  ModifiedEditState(
      {Identifier? id, required Item modified, required this.unmodified})
      : super(id: id, item: modified);

  @override
  String toString() =>
      "${runtimeType.toString()} { id: $id, item: $item, unmodified: $item }";
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
      streamToEmitterAdapterStatusAware(_handleLoadItem),
    );
    on<ModifyItem<Identifier, Item>>(
      streamToEmitterAdapter(_handleModifyItem),
    );
    on<SaveChanges<Identifier, Item>>(
      streamToEmitterAdapterStatusAware(_handleSaveChanges),
    );
    on<DiscardChanges<Identifier, Item>>(
      streamToEmitterAdapter(_handleDiscardChanges),
    );

    repo.changedItems.listen((ids) {
      final current = state;
      final id = current is LoadSuccessEditState<Identifier, Item>
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
    Repository<Identifier, Item, dynamic, dynamic> repo,
    Identifier id,
  ) =>
      EditPageBloc._(repo, false, LoadingItem(id))..add(LoadItem(id));

  factory EditPageBloc.modified(
    Repository<Identifier, Item, dynamic, dynamic> repo,
    Item item,
  ) =>
      EditPageBloc._(
        repo,
        true,
        ModifiedEditState(modified: item, unmodified: item),
      );

  Stream<EditPageBlocState<Identifier, Item>> _handleLoadItem(
    LoadItem event,
  ) async* {
    yield LoadingItem(event.id);
    try {
      final item = await repo.getItem(event.id);
      if (item != null) {
        yield LoadSuccessEditState(id: event.id, item: item);
      } else {
        yield ItemNotFound(event.id);
      }
    } on SocketException catch (err) {
      throw ConnectionException(err);
    }
  }

  Stream<EditPageBlocState<Identifier, Item>> _handleModifyItem(
    ModifyItem event,
  ) async* {
    final current = state;
    if (current is ModifiedEditState<Identifier, Item>) {
      yield ModifiedEditState(
        id: current.id,
        modified: event.modified,
        unmodified: current.unmodified,
      );
    } else if (current is LoadSuccessEditState<Identifier, Item>) {
      yield ModifiedEditState(
        id: current.id,
        modified: event.modified,
        unmodified: current.item,
      );
    } else {
      throw Exception("Impossible event.");
    }
  }

  Stream<EditPageBlocState<Identifier, Item>> _handleSaveChanges(
    SaveChanges event,
  ) async* {
    try {
      final current = state;
      if (current is ModifiedEditState<Identifier, Item>) {
        if (isCreating) {
          final result =
              await repo.createItem(repo.createFromItem(current.item));
          yield LoadSuccessEditState(id: current.id, item: result);
        } else {
          final result = await repo.updateItem(
            current.id!,
            repo.updateFromDiff(current.item, current.unmodified),
          );
          yield LoadSuccessEditState(id: current.id, item: result);
        }
      }
    } on SocketException catch (err) {
      throw ConnectionException(err);
    }
  }

  Stream<EditPageBlocState<Identifier, Item>> _handleDiscardChanges(
    DiscardChanges event,
  ) async* {
    final current = state;
    if (current is ModifiedEditState<Identifier, Item>) {
      yield LoadSuccessEditState(id: current.id, item: current.item);
    }
  }
}
