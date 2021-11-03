export 'budget_details_page.dart';
export 'category_details_page.dart';

import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:smuni/blocs/blocs.dart';
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

class DetailsPageBloc<Identifier, Item, CreateInput, UpdateInput> extends Bloc<
    DetailsPageEvent<Identifier, Item>, DetailsPageState<Identifier, Item>> {
  final ApiRepository<Identifier, Item, CreateInput, UpdateInput> repo;
  final OfflineRepository<Identifier, Item, CreateInput, UpdateInput>
      offlineRepo;
  final AuthBloc authBloc;

  DetailsPageBloc(this.repo, this.offlineRepo, this.authBloc, Identifier id)
      : super(LoadingItem(id)) {
    on<LoadItem<Identifier, Item>>(
      streamToEmitterAdapterStatusAware(_handleLoadItem),
    );
    on<DeleteItem<Identifier, Item>>(
      streamToEmitterAdapterStatusAware(handleDeleteItem),
    );

    repo.changedItems.listen(_changeItemsListener);
    offlineRepo.changedItems.listen(_changeItemsListener);
    add(LoadItem(id));
  }

  void _changeItemsListener(Set<Identifier> ids) {
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
  }

  Stream<DetailsPageState<Identifier, Item>> _handleLoadItem(
    LoadItem<Identifier, Item> event,
  ) async* {
    yield LoadingItem(event.id);
    try {
      final auth = authBloc.authSuccesState();
      final item = await repo.getItem(event.id, auth.username, auth.authToken);
      if (item != null) {
        yield LoadSuccess(event.id, item);
      } else {
        yield ItemNotFound(event.id);
      }
    } catch (err) {
      if (err is SocketException || err is UnauthenticatedException) {
        // do it offline if not connected or authenticated
        final item = await offlineRepo.getItemOffline(event.id);
        if (item != null) {
          yield LoadSuccess(event.id, item);
        } else {
          yield ItemNotFound(event.id);
        }
      } else {
        rethrow;
      }
    }
  }

  Stream<DetailsPageState<Identifier, Item>> handleDeleteItem(
    DeleteItem<Identifier, Item> event,
  ) async* {
    final current = state;

    var totalWait = Duration();
    while (current is LoadingItem) {
      if (totalWait > Duration(seconds: 3)) throw TimeoutException();
      await Future.delayed(const Duration(milliseconds: 500));
      totalWait += const Duration(milliseconds: 500);
    }

    if (current is LoadSuccess<Identifier, Item>) {
      try {
        final auth = authBloc.authSuccesState();
        await repo.removeItem(current.id, auth.username, auth.authToken, true);
        yield ItemNotFound(current.id);
      } catch (err) {
        if (err is SocketException || err is UnauthenticatedException) {
          // do it offline if not connected or authenticated
          await offlineRepo.removeItemOffline(
            current.id,
          );
          yield ItemNotFound(current.id);
        } else {
          rethrow;
        }
      }
    } else if (current is ItemNotFound) {
      throw Exception("impossible event");
    }
  }
}
