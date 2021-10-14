export 'auth.dart';

import 'dart:async';
import 'dart:collection';

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
  Future<void> removeItem(Identifier id);
  Stream<Set<Identifier>> get changedItems;
  UpdateInput updateFromDiff(Item update, Item old);
  CreateInput createFromItem(Item item);
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
  Future<void> removeItem(Identifier id) async {
    await cache.removeItem(id);
    _changedItemsController.add({id});
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

  final Cache<String, User> userCache;
  final Cache<String, Budget> budgetCache;
  final Cache<String, Category> categoryCache;
  final Cache<String, Expense> expenseCache;

  CacheRefresher(
    this.client,
    this.tokenRepo, {
    required ApiUserRepository userRepo,
    required ApiBudgetRepository budgetRepo,
    required ApiCategoryRepository categoryRepo,
    required ApiExpenseRepository expenseRepo,
  })  : userCache = userRepo.cache,
        budgetCache = budgetRepo.cache,
        categoryCache = categoryRepo.cache,
        expenseCache = expenseRepo.cache;

  Future<void> refreshCache() async {
    final user = await client.getUser(
      tokenRepo.username,
      await tokenRepo.accessToken,
    );
    await refreshFromUser(user);
  }

  Future<void> refreshFromUser(UserDenorm user) async {
    await userCache.setItem(user.username, User.from(user));

    for (final budget in user.budgets) {
      await budgetCache.setItem(budget.id, budget);
    }

    for (final category in user.categories) {
      await categoryCache.setItem(category.id, category);
    }

    for (final expense in user.expenses) {
      await expenseCache.setItem(expense.id, expense);
    }
  }
}
