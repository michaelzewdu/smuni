import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:smuni/repositories/repositories.dart';

// EVENTS

abstract class DetailsPageEvent<Identifier, Item> {
  const DetailsPageEvent();
}

class LoadItem<Identifier, Item> extends DetailsPageEvent<Identifier, Item> {
  final Identifier id;
  const LoadItem(this.id);
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
}

class ItemNotFound<Identifier, Item>
    extends DetailsPageState<Identifier, Item> {
  final Identifier id;
  const ItemNotFound(this.id);
}

class LoadSuccess<Identifer, Item> extends DetailsPageState<Identifer, Item> {
  final Identifer id;
  final Item item;

  LoadSuccess(this.id, this.item);
}

// BLOC

class DetailsPageBloc<Identifier, Item> extends Bloc<
    DetailsPageEvent<Identifier, Item>, DetailsPageState<Identifier, Item>> {
  Repository<Identifier, Item> repo;
  DetailsPageBloc(this.repo, Identifier id) : super(LoadingItem(id)) {
    repo.changedItems.listen((ids) {
      if (ids[0] == id) {
        add(LoadItem(id));
      }
    });
    add(LoadItem(id));
  }

  @override
  Stream<DetailsPageState<Identifier, Item>> mapEventToState(
    DetailsPageEvent<Identifier, Item> event,
  ) async* {
    if (event is LoadItem<Identifier, Item>) {
      yield LoadingItem(event.id);
      final item = await repo.getItem(event.id);
      if (item != null) {
        yield LoadSuccess(event.id, item);
        return;
      } else {
        yield ItemNotFound(event.id);
        return;
      }
    } else if (event is DeleteItem<Identifier, Item>) {
      final current = state;
      if (current is LoadSuccess<Identifier, Item>) {
        // TODO
        await repo.removeItem(current.id);
        yield ItemNotFound(current.id);
        return;
      } else if (current is LoadingItem) {
        await Future.delayed(const Duration(milliseconds: 500));
        add(event);
        return;
      } else if (current is ItemNotFound) {
        return;
      }
    }
    throw Exception("Unhandeled event");
  }
}
