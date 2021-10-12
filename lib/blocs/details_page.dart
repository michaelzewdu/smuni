import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';

// EVENTS

abstract class DetailsPageEvent<Identifier, Item> {
  const DetailsPageEvent();
}

class LoadItem<Identifier, Item> extends DetailsPageEvent<Identifier, Item> {
  final Identifier id;
  const LoadItem(this.id);

  @override
  String toString() => "${runtimeType.toString()} { id: $id, }";
}

class DeleteItem<Identifier, Item> extends DetailsPageEvent<Identifier, Item> {
  const DeleteItem();
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
      streamToEmitterAdapter(_handleLoadItem),
    );
    on<DeleteItem<Identifier, Item>>(
      streamToEmitterAdapter(_handleDeleteItem),
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
      LoadItem<Identifier, Item> event) async* {
    yield LoadingItem(event.id);
    final item = await repo.getItem(event.id);
    if (item != null) {
      yield LoadSuccess(event.id, item);
    } else {
      yield ItemNotFound(event.id);
    }
  }

  Stream<DetailsPageState<Identifier, Item>> _handleDeleteItem(
      DeleteItem<Identifier, Item> event) async* {
    final current = state;
    if (current is LoadSuccess<Identifier, Item>) {
      await repo.removeItem(current.id);
      yield ItemNotFound(current.id);
    } else if (current is LoadingItem) {
      await Future.delayed(const Duration(milliseconds: 500));
      add(event);
    } else if (current is ItemNotFound) {
      throw Exception("impossible event");
    }
  }
}
