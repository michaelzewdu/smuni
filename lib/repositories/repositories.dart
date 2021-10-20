export 'auth.dart';

import 'dart:async';

import 'package:smuni/models/models.dart';
import 'package:smuni/providers/cache/cache.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

import 'auth.dart';
import 'budget.dart';
import 'category.dart';
import 'expense.dart';
import 'user.dart';

abstract class Repository<Identifier, Item, CreateInput, UpdateInput> {
  Future<Item?> getItem(Identifier id);
  Future<Map<Identifier, Item>> getItems();
  Future<Item> createItem(CreateInput input, [Identifier? id]);
  Future<Item> updateItem(Identifier id, UpdateInput input);
  Future<void> removeItem(
    Identifier id, [
    bool bypassChangedItemNotification = false,
  ]);

  Stream<Set<Identifier>> get changedItems;

  UpdateInput updateFromDiff(Item update, Item old);
  CreateInput createFromItem(Item item);
  Future<void> refreshCache(Map<Identifier, Item> items);
}

typedef UserRepository = ApiUserRepository;
typedef BudgetRepository = ApiBudgetRepository;
typedef CategoryRepository = ApiCategoryRepository;
typedef ExpenseRepository = ApiExpenseRepository;

class SimpleRepository<Identifier, Item>
    extends Repository<Identifier, Item, Item, Item> {
  final Cache<Identifier, Item> cache;

  SimpleRepository(this.cache);

  final StreamController<Set<Identifier>> _changedItemsController =
      StreamController.broadcast();

  @override
  Stream<Set<Identifier>> get changedItems => _changedItemsController.stream;

  @override
  Future<Item?> getItem(Identifier id) => cache.getItem(id);

  @override
  Future<Map<Identifier, Item>> getItems() => cache.getItems();
  @override
  Future<void> removeItem(
    Identifier id, [
    bool bypassChangedItemNotification = false,
  ]) async {
    await cache.removeItem(id);
    if (!bypassChangedItemNotification) _changedItemsController.add({id});
  }

  @override
  Future<Item> createItem(Item input, [Identifier? id]) async {
    if (await cache.getItem(id!) != null) {
      throw Exception("Identifier occupied");
    }
    await cache.setItem(id, input);
    _changedItemsController.add({id});
    return input;
  }

  @override
  Future<Item> updateItem(Identifier id, Item input) async {
    await cache.setItem(id, input);
    _changedItemsController.add({id});
    return input;
  }

  @override
  Item updateFromDiff(Item update, Item old) => update;

  @override
  Item createFromItem(Item item) => item;

  @override
  Future<void> refreshCache(Map<Identifier, Item> items) async {
    await cache.clear();
    Set<Identifier> ids = {};
    for (final p in items.entries) {
      ids.add(p.key);
      await cache.setItem(p.key, p.value);
    }
    _changedItemsController.add(ids);
  }
}

class SimpleUserRepository extends SimpleRepository<String, User> {
  SimpleUserRepository(Cache<String, User> cache) : super(cache);
}

class SimpleBudgetRepository extends SimpleRepository<String, Budget> {
  SimpleBudgetRepository(Cache<String, Budget> cache) : super(cache);
}

class SimpleCategoryRepository extends SimpleRepository<String, Category> {
  Future<Map<String, TreeNode<String>>>? _ancestryGraph;

  SimpleCategoryRepository(Cache<String, Category> cache) : super(cache);

  Future<Map<String, TreeNode<String>>> get ancestryGraph {
    _ancestryGraph ??= _calcAncestryTree();
    return _ancestryGraph!;
  }

  @override
  Future<Category> createItem(Category input, [String? id]) async {
    final update = super.createItem(input, id);
    _ancestryGraph = null;
    return update;
  }

  @override
  Future<Category> updateItem(String id, Category input) async {
    final update = super.updateItem(id, input);
    _ancestryGraph = null;
    return update;
  }

  // FIXME: fix this func
  Future<Map<String, TreeNode<String>>> _calcAncestryTree() async {
    final nodes = <String, TreeNode<String>>{};
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

class SimpleExpenseRepository extends SimpleRepository<String, Expense> {
  SimpleExpenseRepository(Cache<String, Expense> cache) : super(cache);

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
          .map((e) => e.timestamp),
    );
  }

  Future<Iterable<Expense>> getItemsInRange(DateRange range,
      {Set<String>? ofBudgets, Set<String>? ofCategories}) async {
    final items = await getItems();
    return items.values.where(
      ofBudgets != null && ofCategories != null
          ? (e) =>
              range.containsTimestamp(e.timestamp) &&
              ofBudgets.contains(e.budgetId) &&
              ofCategories.contains(e.categoryId)
          : ofBudgets != null
              ? (e) =>
                  range.containsTimestamp(e.timestamp) &&
                  ofBudgets.contains(e.budgetId)
              : ofCategories != null
                  ? (e) =>
                      range.containsTimestamp(e.timestamp) &&
                      ofCategories.contains(e.categoryId)
                  : (e) => range.containsTimestamp(e.timestamp),
    );
  }
}

class ItemNotFoundException implements Exception {
  final String identifier;

  const ItemNotFoundException(this.identifier);
}

T? ifNotEqualTo<T>(T value, T ifNotEqualTo) =>
    value != ifNotEqualTo ? value : null;

// FIXME: bad idea
class CacheRefresher {
  final SmuniApiClient client;
  final AuthTokenRepository tokenRepo;

  final ApiUserRepository userRepo;
  final ApiBudgetRepository budgetRepo;
  final ApiCategoryRepository categoryRepo;
  final ApiExpenseRepository expenseRepo;

  CacheRefresher(
    this.client,
    this.tokenRepo, {
    required this.userRepo,
    required this.budgetRepo,
    required this.categoryRepo,
    required this.expenseRepo,
  });

  Future<void> refreshCache() async {
    final user = await client.getUser(
      tokenRepo.username,
      await tokenRepo.accessToken,
    );
    await refreshFromUser(user);
  }

  Future<void> refreshFromUser(UserDenorm user) async {
    await userRepo.refreshCache({user.username: User.from(user)});
    await budgetRepo.refreshCache(
      {for (final item in user.budgets) item.id: item},
    );
    await categoryRepo.refreshCache(
      {for (final item in user.categories) item.id: item},
    );
    await expenseRepo.refreshCache(
      {for (final item in user.expenses) item.id: item},
    );
  }
}
