import 'dart:async';

export 'sqlite.dart';

abstract class Cache<Identifier, Item> {
  Future<void> clear();
  Future<Item?> getItem(Identifier id);
  Future<Map<Identifier, Item>> getItems();
  Future<void> setItem(Identifier id, Item item);
  Future<void> removeItem(Identifier id);
  // Stream<List<Identifier>> get changedItems;
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
