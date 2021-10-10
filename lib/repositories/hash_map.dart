import 'dart:async';

import 'repositories.dart';

class HashMapCache<Identifier, Item> extends Cache<Identifier, Item> {
  final Map<Identifier, Item> _items = {};

  @override
  Future<Item?> getItem(Identifier id) async {
    return _items[id];
  }

  @override
  Future<void> setItem(Identifier id, Item item) async {
    _items[id] = item;
    _changedItemsController.add([id]);
  }

  @override
  Future<void> removeItem(Identifier id) async {
    _items.remove(id);
    _changedItemsController.add([id]);
  }

  @override
  Future<Map<Identifier, Item>> getItems() async {
    return _items;
  }

  final StreamController<List<Identifier>> _changedItemsController =
      StreamController.broadcast();

  @override
  Stream<List<Identifier>> get changedItems => _changedItemsController.stream;
}
