import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

// EVENTS

abstract class DetailsPageEvent<Identifier, Item> {
  const DetailsPageEvent();
}

class LoadItem<Identifier, Item> extends DetailsPageEvent<Identifier, Item>
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

class DeleteItem<Identifier, Item> extends DetailsPageEvent<Identifier, Item>
    with StatusAwareEvent {
  DeleteItem({
    OperationSuccessNotifier? onSuccess,
    OperationExceptionNotifier? onError,
  }) {
    this.onSuccess = onSuccess;
    this.onError = onError;
  }
}

// STATE

abstract class DetailsPageState<Identifier, Item> {
  const DetailsPageState();
}

class LoadingItem<Identifier, Item> extends DetailsPageState<Identifier, Item> {
  final Identifier id;
  const LoadingItem(this.id);

  @override
  String toString() => "${runtimeType.toString()} { id: $id, }";
}

class ItemNotFound<Identifier, Item>
    extends DetailsPageState<Identifier, Item> {
  final Identifier id;
  const ItemNotFound(this.id);

  @override
  String toString() => "${runtimeType.toString()} { id: $id, }";
}

class LoadSuccess<Identifer, Item> extends DetailsPageState<Identifer, Item> {
  final Identifer id;
  final Item item;

  LoadSuccess(this.id, this.item);

  @override
  String toString() => "${runtimeType.toString()} { id: $id, item: $item }";
}

// BLOC

class DetailsPageBloc<Identifier, Item> extends Bloc<
    DetailsPageEvent<Identifier, Item>, DetailsPageState<Identifier, Item>> {
  Repository<Identifier, Item, dynamic, dynamic> repo;
  DetailsPageBloc(this.repo, Identifier id) : super(LoadingItem(id)) {
    on<LoadItem<Identifier, Item>>(
      streamToEmitterAdapterStatusAware(_handleLoadItem),
    );
    on<DeleteItem<Identifier, Item>>(
      streamToEmitterAdapterStatusAware(handleDeleteItem),
    );

    repo.changedItems.listen((ids) {
      final current = state;
      final id = current is LoadSuccess<Identifier, Item>
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
    add(LoadItem(id));
  }

  Stream<DetailsPageState<Identifier, Item>> _handleLoadItem(
    LoadItem<Identifier, Item> event,
  ) async* {
    yield LoadingItem(event.id);
    try {
      final item = await repo.getItem(event.id);
      if (item != null) {
        yield LoadSuccess(event.id, item);
      } else {
        yield ItemNotFound(event.id);
      }
    } on SocketException catch (err) {
      throw ConnectionException(err);
    }
  }

  Stream<DetailsPageState<Identifier, Item>> handleDeleteItem(
    DeleteItem<Identifier, Item> event,
  ) async* {
    try {
      final current = state;

      var totalWait = Duration();
      while (current is LoadingItem) {
        if (totalWait > Duration(seconds: 3)) throw TimeoutException();
        await Future.delayed(const Duration(milliseconds: 500));
        totalWait += const Duration(milliseconds: 500);
      }

      if (current is LoadSuccess<Identifier, Item>) {
        await repo.removeItem(current.id);
        yield ItemNotFound(current.id);
        return;
      } else if (current is ItemNotFound) {
        throw Exception("impossible event");
      }
    } on SocketException catch (err) {
      throw ConnectionException(err);
    }
  }
}
