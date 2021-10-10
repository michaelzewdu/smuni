export 'hash_map.dart';
export 'sqlite.dart';

import 'dart:async';

abstract class Repository<Identfier, Item> {
  Future<Item?> getItem(Identfier id);
  Future<Map<Identfier, Item>> getItems();
  Future<void> setItem(Identfier id, Item item);
  Future<void> removeItem(Identfier id);
  Stream<List<Identfier>> get changedItems;
}

class TreeNode<T> {
  final TreeNode<T>? parent;
  final T item;
  final List<T> children;

  TreeNode(this.item, {required this.children, this.parent});
}
