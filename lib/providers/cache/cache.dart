import 'dart:async';

export 'sqlite.dart';

abstract class Cache<Identifier, Item> {
  Future<void> clear();
  Future<Item?> getItem(Identifier id);
  Future<Map<Identifier, Item>> getItems();
  Future<void> setItem(Identifier id, Item item);
  Future<void> removeItem(Identifier id);
}

abstract class RemovedItemsCache<Identifier> {
  Future<void> clear();
  Future<bool> has(Identifier id);
  Future<List<Identifier>> getItems();
  Future<void> add(Identifier id);
  Future<void> remove(Identifier id);
}

class MapCache<Identifier, Item> extends Cache<Identifier, Item> {
  final _items = <Identifier, Item>{};

  @override
  Future<Item?> getItem(Identifier id) async {
    return _items[id];
  }

  @override
  Future<void> setItem(Identifier id, Item item) async {
    _items[id] = item;
  }

  @override
  Future<void> removeItem(Identifier id) async {
    _items.remove(id);
  }

  @override
  Future<Map<Identifier, Item>> getItems() async {
    return _items;
  }

  @override
  Future<void> clear() async {
    _items.clear();
  }
}

class SetRemovedItemsCache<Identifier> extends RemovedItemsCache<Identifier> {
  final removedItems = <Identifier>{};

  @override
  Future<void> add(Identifier id) async {
    removedItems.add(id);
  }

  @override
  Future<void> clear() async {
    removedItems.clear();
  }

  @override
  Future<List<Identifier>> getItems() async {
    return removedItems.toList();
  }

  @override
  Future<bool> has(Identifier id) async {
    return removedItems.contains(id);
  }

  @override
  Future<void> remove(Identifier id) async {
    removedItems.remove(id);
  }
}
