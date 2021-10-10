export 'hash_map.dart';
export 'sqlite.dart';

import 'dart:async';
import 'dart:collection';

import 'package:smuni/models/models.dart';
import 'package:smuni/utilities.dart';

abstract class Repository<Identifier, Item> {
  Future<Item?> getItem(Identifier id);
  Future<Map<Identifier, Item>> getItems();
  Future<void> setItem(Identifier id, Item item);
  Future<void> removeItem(Identifier id);
  Stream<List<Identifier>> get changedItems;
}

abstract class Cache<Identifier, Item> {
  Future<Item?> getItem(Identifier id);
  Future<Map<Identifier, Item>> getItems();
  Future<void> setItem(Identifier id, Item item);
  Future<void> removeItem(Identifier id);
  Stream<List<Identifier>> get changedItems;
}

class TreeNode<T> {
  final TreeNode<T>? parent;
  final T item;
  final List<T> children;

  TreeNode(this.item, {required this.children, this.parent});
}

class SimpleRepository<Identifier, Item> extends Repository<Identifier, Item> {
  final Cache<Identifier, Item> cache;

  SimpleRepository(this.cache);

  @override
  Stream<List<Identifier>> get changedItems => cache.changedItems;

  @override
  Future<Item?> getItem(Identifier id) => cache.getItem(id);

  @override
  Future<Map<Identifier, Item>> getItems() => cache.getItems();
  @override
  Future<void> removeItem(Identifier id) => cache.removeItem(id);

  @override
  Future<void> setItem(Identifier id, Item item) => cache.setItem(id, item);
}

class UserRepository extends SimpleRepository<String, User> {
  UserRepository(Cache<String, User> cache) : super(cache);
}

class BudgetRepository extends SimpleRepository<String, Budget> {
  BudgetRepository(Cache<String, Budget> cache) : super(cache);
}

class CategoryRepository extends SimpleRepository<String, Category> {
  Future<Map<String, TreeNode<String>>>? _ancestryGraph;

  CategoryRepository(Cache<String, Category> cache) : super(cache);

  Future<Map<String, TreeNode<String>>> get ancestryGraph {
    _ancestryGraph ??= _calcAncestryTree();
    return _ancestryGraph!;
  }

  @override
  Future<void> setItem(String id, Category item) async {
    await super.setItem(id, item);
    _ancestryGraph = null;
  }

  // FIXME: fix this func
  Future<Map<String, TreeNode<String>>> _calcAncestryTree() async {
    Map<String, TreeNode<String>> nodes = HashMap();
    final items = await getItems();

    TreeNode<String> getTreeNode(Category category) {
      var node = nodes[category.id];
      if (node == null) {
        TreeNode<String>? parentNode;
        if (category.parentId != null) {
          final parent = items[category.parentId];
          if (parent == null) {
            throw Exception("parent not found at id: $category.parentId");
          }
          parentNode = getTreeNode(parent);
          parentNode.children.add(category.id);
        }
        node = TreeNode(category.id, children: [], parent: parentNode);
        nodes[category.id] = node;
      }
      return node;
    }

    for (final category in items.values) {
      if (!nodes.containsKey(category.id)) {
        getTreeNode(category);
      }
    }
    return nodes;
  }

  /// The returned list includes the given id.
  /// Returns null if no category found under id.
  Future<List<String>?> getCategoryDescendantsTree(String forId) async {
    final graph = await ancestryGraph;
    final rootNode = graph[forId];
    if (rootNode == null) return null;

    List<String> descendants = [forId];
    void appendChildren(TreeNode<String> node) {
      descendants.addAll(node.children);
      for (final child in node.children) {
        final childNode = graph[child];
        if (childNode == null) {
          throw Exception("childNode not found in ancestryGraph at id: $child");
        }
        appendChildren(childNode);
      }
    }

    appendChildren(rootNode);

    return descendants;
  }
}

class ExpenseRepository extends SimpleRepository<String, Expense> {
  ExpenseRepository(Cache<String, Expense> cache) : super(cache);

  Future<Map<DateRange, DateRangeFilter>> getDateRangeFilters(
      {Set<String>? ofBudgets, Set<String>? ofCategories}) async {
    final items = await getItems();
    return generateDateRangesFilters(
      items.values
          .where(ofBudgets != null && ofCategories != null
              ? (e) =>
                  ofBudgets.contains(e.budgetId) &&
                  ofCategories.contains(e.categoryId)
              : ofBudgets != null
                  ? (e) => ofBudgets.contains(e.budgetId)
                  : ofCategories != null
                      ? (e) => ofCategories.contains(e.categoryId)
                      : (e) => true)
          .map((e) => e.createdAt),
    );
  }

  Future<Iterable<Expense>> getItemsInRange(DateRange range,
      {Set<String>? ofBudgets, Set<String>? ofCategories}) async {
    final items = await getItems();
    return items.values.where(
      ofBudgets != null && ofCategories != null
          ? (e) =>
              range.containsTimestamp(e.createdAt) &&
              ofBudgets.contains(e.budgetId) &&
              ofCategories.contains(e.categoryId)
          : ofBudgets != null
              ? (e) =>
                  range.containsTimestamp(e.createdAt) &&
                  ofBudgets.contains(e.budgetId)
              : ofCategories != null
                  ? (e) =>
                      range.containsTimestamp(e.createdAt) &&
                      ofCategories.contains(e.categoryId)
                  : (e) => range.containsTimestamp(e.createdAt),
    );
  }
}
