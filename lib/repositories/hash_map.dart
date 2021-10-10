import 'dart:async';
import 'dart:collection';

import 'package:smuni/models/models.dart';
import 'package:smuni/utilities.dart';

import 'repositories.dart';

class HashMapRepository<Identfier, Item> extends Repository<Identfier, Item> {
  final Map<Identfier, Item> _items = {};

  @override
  Future<Item?> getItem(Identfier id) async {
    return _items[id];
  }

  @override
  Future<void> setItem(Identfier id, Item item) async {
    _items[id] = item;
    _changedItemsController.add([id]);
  }

  @override
  Future<void> removeItem(Identfier id) async {
    _items.remove(id);
    _changedItemsController.add([id]);
  }

  @override
  Future<Map<Identfier, Item>> getItems() async {
    return _items;
  }

  final StreamController<List<Identfier>> _changedItemsController =
      StreamController.broadcast();

  @override
  Stream<List<Identfier>> get changedItems => _changedItemsController.stream;
}

class UserRepository extends HashMapRepository<String, User> {}

class BudgetRepository extends HashMapRepository<String, Budget> {}

class CategoryRepository extends HashMapRepository<String, Category> {
  Future<Map<String, TreeNode<String>>>? _ancestryGraph;
  Future<Map<String, TreeNode<String>>> get ancestryGraph {
    _ancestryGraph ??= Future.value(_calcAncestryTree());
    return _ancestryGraph!;
  }

  @override
  Future<void> setItem(String id, Category item) async {
    await super.setItem(id, item);
    _ancestryGraph = null;
  }

  // FIXME: fix this func
  Map<String, TreeNode<String>> _calcAncestryTree() {
    Map<String, TreeNode<String>> nodes = HashMap();

    TreeNode<String> getTreeNode(Category category) {
      var node = nodes[category.id];
      if (node == null) {
        TreeNode<String>? parentNode;
        if (category.parentId != null) {
          final parent = _items[category.parentId];
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

    for (final category in _items.values) {
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

class ExpenseRepository extends HashMapRepository<String, Expense> {
  /*  Future<Map<DateRange, DateRangeFilter>>? _filtersFuture;
  Future<Map<DateRange, DateRangeFilter>> get dateRangeFilters {
    if (_filtersFuture == null) {
      _filtersFuture = new Future.value(
        generateDateRangesFilters(this._items.values.map((e) => e.createdAt)),
      );
    }
    return _filtersFuture!;
  } */

  Future<Map<DateRange, DateRangeFilter>> getDateRangeFilters(
      {Set<String>? ofBudgets, Set<String>? ofCategories}) async {
    return generateDateRangesFilters(
      _items.values
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
    return _items.values.where(
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
