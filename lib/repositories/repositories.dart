export 'auth.dart';
export 'budget.dart';
export 'expense.dart';
export 'category.dart';
export 'income.dart';
export 'user.dart';

import 'dart:async';

import 'package:smuni/models/models.dart';
import 'package:smuni/providers/cache/cache.dart';
import 'package:smuni/repositories/category.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

import 'budget.dart';
import 'expense.dart';
import 'user.dart';
import 'income.dart';

abstract class ApiRepository<Identifier, Item, CreateInput, UpdateInput> {
  Future<Item?> getItem(Identifier id, String username, String authToken);
  Future<Map<Identifier, Item>> getItems();
  Future<Item> createItem(CreateInput input, String username, String authToken);
  Future<Item> updateItem(
    Identifier id,
    UpdateInput input,
    String username,
    String authToken,
  );
  Future<void> removeItem(
    Identifier id,
    String username,
    String authToken, [
    bool bypassChangedItemNotification = false,
  ]);

  Stream<Set<Identifier>> get changedItems;

  UpdateInput updateFromDiff(Item update, Item old);
  CreateInput createFromItem(Item item);
  Future<void> refreshCache(Map<Identifier, Item> items);
}

abstract class ApiRepositoryWrapper<Identifier, Item, CreateInput, UpdateInput>
    extends ApiRepository<Identifier, Item, CreateInput, UpdateInput> {
  final ApiRepository<Identifier, Item, CreateInput, UpdateInput> repo;

  ApiRepositoryWrapper(this.repo);

  @override
  Stream<Set<Identifier>> get changedItems => repo.changedItems;

  @override
  CreateInput createFromItem(Item item) => repo.createFromItem(item);

  @override
  Future<Item> createItem(
    CreateInput input,
    String username,
    String authToken,
  ) =>
      repo.createItem(input, username, authToken);

  @override
  Future<Item?> getItem(
    Identifier id,
    String username,
    String authToken,
  ) =>
      repo.getItem(id, username, authToken);

  @override
  Future<Map<Identifier, Item>> getItems() => repo.getItems();

  @override
  Future<void> refreshCache(Map<Identifier, Item> items) {
    return repo.refreshCache(items);
  }

  @override
  Future<void> removeItem(Identifier id, String username, String authToken,
          [bool bypassChangedItemNotification = false]) =>
      repo.removeItem(id, username, authToken, bypassChangedItemNotification);

  @override
  Future<Item> updateItem(
    Identifier id,
    UpdateInput input,
    String username,
    String authToken,
  ) =>
      repo.updateItem(id, input, username, authToken);

  @override
  UpdateInput updateFromDiff(Item update, Item old) =>
      repo.updateFromDiff(update, old);
}

/* mixin OfflineCapableRepository<Identifier, Item, CreateInput, UpdateInput>
    on ApiRepository<Identifier, Item, CreateInput, UpdateInput> {

  Future<Item> getItemOffline(Identifier id);
  Future<Item> createItemOffline(Identifier id, Item input);
  Future<Item> updateItemOffline(Identifier id, Item update);
  Future<void> removeItemOffline(Identifier id);
} */

abstract class OfflineRepository<Identifier, Item, CreateInput, UpdateInput> {
  final Cache<Identifier, Item> cache;
  final Cache<Identifier, Item> serverVersionCache;
  final RemovedItemsCache<Identifier> removedItemsCache;
  /* OfflineRepository(
    ApiRepositoryWrapper<String, Category, CreateInput, UpdateInput> repo,
    this.cache,
    this.serverSeenItemsCache,
  ) : super(repo);
 */
  OfflineRepository(
      this.cache, this.serverVersionCache, this.removedItemsCache);

  final StreamController<Set<Identifier>> _changedItemsController =
      StreamController.broadcast();

  Stream<Set<Identifier>> get changedItems => _changedItemsController.stream;

  Future<Item?> getItemOffline(
    Identifier id,
  ) =>
      cache.getItem(id);

  Future<Map<Identifier, Item>> getItemsOffline() => cache.getItems();

  Future<Item> createItemOffline(CreateInput input) async {
    final p = itemFromCreateInput(input);
    await cache.setItem(p.a, p.b);
    _changedItemsController.add({p.a});
    return p.b;
  }

  Future<Item> updateItemOffline(
    Identifier id,
    UpdateInput update,
  ) async {
    final item = await cache.getItem(id);
    if (item == null) throw ItemNotFoundException(id);
    // if we haven't cached a server version
    if (await serverVersionCache.getItem(id) == null) {
      await serverVersionCache.setItem(id, item);
    }
    final updated = itemFromUpdateInput(item, update);
    await cache.setItem(id, updated);
    _changedItemsController.add({id});
    return updated;
  }

  Future<void> removeItemOffline(Identifier id) async {
    await serverVersionCache.removeItem(id);
    final item = await cache.getItem(id);
    if (item == null) return;
    await cache.removeItem(id);
    if (isServerVersion(item)) await removedItemsCache.add(id);
    _changedItemsController.add({id});
  }

  bool isServerVersion(Item item);

  /// This expects you to mark the created item with some way to identify
  /// the created items later.
  Pair<Identifier, Item> itemFromCreateInput(CreateInput input);

  /// This expects you to mark the created item with some way to identify
  /// the updated items later.
  Item itemFromUpdateInput(Item item, UpdateInput input);

  /// Use whatever marker you added on [`itemFromCreateInput`] to identify the
  /// new items.
  Future<List<Pair<Identifier, CreateInput>>> getPendingCreates();

  /// Use whatever marker you added on [`itemFromUpdateInput`] to identify the
  /// new items.
  Future<Map<Identifier, UpdateInput>> getPendingUpdates();

  Future<List<Identifier>> getPendingDeletes() => removedItemsCache.getItems();
}

typedef UserRepository = ApiUserRepository;
typedef BudgetRepository = ApiBudgetRepository;

class CategoryRepositoryExt<CreateInput, UpdateInput>
    extends ApiRepositoryWrapper<String, Category, CreateInput, UpdateInput> {
  CategoryRepositoryExt(
    ApiRepository<String, Category, CreateInput, UpdateInput> repo,
  ) : super(repo);

  /*  @override
  Future<Category> createItem(
    CreateInput input,
    String username,
    String authToken,
  ) {
    _ancestryGraph = null;
    return super.createItem(
      input,
      username,
      authToken,
    );
  }

  @override
  Future<void> refreshCache(Map<String, Category> items) {
    _ancestryGraph = null;
    return super.refreshCache(items);
  }

  @override
  Future<Category> updateItem(
    String id,
    UpdateInput input,
    String username,
    String authToken,
  ) {
    _ancestryGraph = null;
    return repo.updateItem(id, input, username, authToken);
  } */

  static Map<String, TreeNode<String>> calcAncestryTree(
    /// The set of items we're interested in
    Set<String> forItems,

    /// The set of all items, must include all items in [`forItems`].
    Map<String, Category> allItems,
  ) {
    final nodes = <String, TreeNode<String>>{};

    TreeNode<String> getTreeNode(Category category) {
      var node = nodes[category.id];

      if (node == null) {
        TreeNode<String>? parentNode;
        if (category.parentId != null) {
          /// look up parents in the allItems set
          final parent = allItems[category.parentId];
          if (parent == null) {
            throw Exception("parent not found at id: ${category.parentId}");
          }
          parentNode = getTreeNode(parent);
          parentNode.children.add(category.id);
        }
        node = TreeNode(category.id, children: [], parent: parentNode);
        nodes[category.id] = node;
      }
      return node;
    }

    for (final id in forItems) {
      if (!nodes.containsKey(id)) {
        final item = allItems[id];
        if (item == null) {
          throw Exception("integrity error, no category found under id $id");
        }
        getTreeNode(item);
      }
    }
    return nodes;
  }

  /* Future<Map<String, TreeNode<String>>>? _ancestryGraph;
  Future<Map<String, TreeNode<String>>> get ancestryGraph =>
      _ancestryGraph ??= _calcAncestryTree();

  Future<Map<String, TreeNode<String>>> _calcAncestryTree() async {
    final items = await getItems();
    return calcAncestryTree(items.keys.toSet(), items);
  } */

  /// The returned list includes the given id.
  /// Returns null if no category found under id.
  Future<List<String>?> getCategoryDescendantsTree(String forId) async {
    final allItems = await getItems();
    final graph = calcAncestryTree(allItems.keys.toSet(), allItems);
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

class CategoryRepository
    extends CategoryRepositoryExt<CreateCategoryInput, UpdateCategoryInput> {
  CategoryRepository(Cache<String, Category> cache, SmuniApiClient client)
      : super(ApiCategoryRepository(cache, client));
}

typedef ExpenseRepository = ApiExpenseRepository;

extension ExpenseRepositoryExt<CreateInput, UpdateInput>
    on ApiRepository<String, Expense, CreateInput, UpdateInput> {
  Future<Map<DateRange, DateRangeFilter>> getDateRangeFilters({
    Set<String>? ofBudgets,
    Set<String>? ofCategories,
  }) async {
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

  Future<Iterable<Expense>> getItemsInRange(
    DateRange range, {
    Set<String>? ofBudgets,
    Set<String>? ofCategories,
  }) async {
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

typedef IncomeRepository = ApiIncomeRepository;

/* class SimpleRepository<Identifier, Item>
    extends ApiRepository<Identifier, Item, Item, Item> {
  final Cache<Identifier, Item> cache;

  SimpleRepository(this.cache);

  final StreamController<Set<Identifier>> _changedItemsController =
      StreamController.broadcast();

  @override
  Stream<Set<Identifier>> get changedItems => _changedItemsController.stream;

  @override
  Future<Item?> getItem(Identifier id, String username, String authToken) =>
      cache.getItem(id);

  @override
  Future<Map<Identifier, Item>> getItems() => cache.getItems();
  @override
  Future<void> removeItem(
    Identifier id,
    String username,
    String authToken, [
    bool bypassChangedItemNotification = false,
  ]) async {
    await cache.removeItem(id);
    if (!bypassChangedItemNotification) _changedItemsController.add({id});
  }

  @override
  Future<Item> createItem(Item input, String username, String authToken,
      [Identifier? id]) async {
    if (await cache.getItem(id!) != null) {
      throw Exception("Identifier occupied");
    }
    await cache.setItem(id, input);
    _changedItemsController.add({id});
    return input;
  }

  @override
  Future<Item> updateItem(
      Identifier id, Item input, String username, String authToken) async {
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
} */

class ItemNotFoundException<Identifier> implements Exception {
  final Identifier identifier;

  const ItemNotFoundException(this.identifier);
}

T? ifNotEqualTo<T>(T value, T ifNotEqualTo) =>
    value != ifNotEqualTo ? value : null;

// FIXME: bad idea
// TODO: research offline first approach more
class CacheSynchronizer {
  final SmuniApiClient client;

  final UserRepository userRepo;
  // final ApiRepository<String, User, dynamic, dynamic> userRepo;
  final BudgetRepository budgetRepo;
  final CategoryRepository categoryRepo;
  final ExpenseRepository expenseRepo;
  final IncomeRepository incomeRepo;

  final OfflineBudgetRepository offlineBudgetRepo;
  final OfflineCategoryRepository offlineCategoryRepo;
  final OfflineExpenseRepository offlineExpenseRepo;
  final OfflineIncomeRepository offlineIncomeRepo;

  CacheSynchronizer(
    this.client, {
    required this.userRepo,
    required this.budgetRepo,
    required this.categoryRepo,
    required this.expenseRepo,
    required this.incomeRepo,
    required this.offlineBudgetRepo,
    required this.offlineCategoryRepo,
    required this.offlineExpenseRepo,
    required this.offlineIncomeRepo,
  });

  Future<void> syncPendingChanges(String username, String authToken) async {
    {
      final repo = categoryRepo;
      final offlineRepo = offlineCategoryRepo;
      final newCategoryIdMap = <String, String>{};
      for (final e in (await offlineRepo.getPendingCreates())) {
        final input = e.b;
        final item = await repo.createItem(
            CreateCategoryInput(
                name: input.name,
                parentId: input.parentId != null
                    ? newCategoryIdMap[input.parentId] ?? input.parentId
                    : null,
                tags: input.tags),
            username,
            authToken);
        newCategoryIdMap[e.a] = item.id;

        /// update expenses in cache
        /// in case refresh fails before we get to update them
        /// on the server
        for (final expense in await expenseRepo
            .getItemsInRange(DateRange(), ofCategories: {e.a})) {
          await expenseRepo.cache
              .setItem(expense.id, Expense.from(expense, categoryId: item.id));
        }

        /// do the same for the budgets in cache
        for (final budget
            in (await offlineBudgetRepo.getItemsOffline()).values) {
          if (budget.categoryAllocations.containsKey(e.a)) {
            await offlineBudgetRepo.cache.setItem(
              budget.id,
              Budget.from(budget, categoryAllocations: {
                for (final allocation in budget.categoryAllocations.entries)
                  if (allocation.key == e.a)
                    item.id: allocation.value
                  else
                    allocation.key: allocation.value
              }),
            );
          }
        }

        /// do the same for the categories in cache
        for (final category
            in (await offlineCategoryRepo.getItemsOffline()).values) {
          if (category.parentId == e.a) {
            await offlineCategoryRepo.cache.setItem(
              category.id,
              Category.from(category, parentId: item.id),
            );
          }
        }
        await offlineRepo.cache.removeItem(e.a);
      }
      for (final e in (await offlineRepo.getPendingUpdates()).entries) {
        await repo.updateItem(e.key, e.value, username, authToken);
      }
      for (final id in await offlineRepo.getPendingDeletes()) {
        await repo.removeItem(id, username, authToken);
        await offlineRepo.removedItemsCache.remove(id);
      }
    }

    {
      final repo = budgetRepo;
      final offlineRepo = offlineBudgetRepo;
      for (final e in (await offlineRepo.getPendingCreates())) {
        final input = e.b;
        final item = await repo.createItem(input, username, authToken);

        /// update expenses in cache
        /// in case refresh fails before we get to update them
        /// on the server
        for (final expense in await expenseRepo
            .getItemsInRange(DateRange(), ofBudgets: {e.a})) {
          await expenseRepo.cache
              .setItem(expense.id, Expense.from(expense, budgetId: item.id));
        }

        await offlineRepo.cache.removeItem(e.a);
      }
      for (final e in (await offlineRepo.getPendingUpdates()).entries) {
        await repo.updateItem(e.key, e.value, username, authToken);
      }
      for (final id in await offlineRepo.getPendingDeletes()) {
        await repo.removeItem(id, username, authToken);
        await offlineRepo.removedItemsCache.remove(id);
      }
    }
    {
      final repo = expenseRepo;
      final offlineRepo = offlineExpenseRepo;
      for (final e in (await offlineRepo.getPendingCreates())) {
        await repo.createItem(e.b, username, authToken);
        await offlineRepo.cache.removeItem(e.a);
      }
      for (final e in (await offlineRepo.getPendingUpdates()).entries) {
        await repo.updateItem(e.key, e.value, username, authToken);
      }
      for (final id in await offlineRepo.getPendingDeletes()) {
        await repo.removeItem(id, username, authToken);
        await offlineRepo.removedItemsCache.remove(id);
      }
    }
    {
      final repo = incomeRepo;
      final offlineRepo = offlineIncomeRepo;
      for (final e in (await offlineRepo.getPendingCreates())) {
        await repo.createItem(e.b, username, authToken);
        await offlineRepo.cache.removeItem(e.a);
      }
      for (final e in (await offlineRepo.getPendingUpdates()).entries) {
        await repo.updateItem(e.key, e.value, username, authToken);
      }
      for (final id in await offlineRepo.getPendingDeletes()) {
        await repo.removeItem(id, username, authToken);
        await offlineRepo.removedItemsCache.remove(id);
      }
    }
  }

  Future<UserDenorm> refreshCache(String username, String authToken) async {
    final user = await client.getUser(username, authToken);
    await refreshFromUser(user);
    return user;
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
    await incomeRepo.refreshCache(
      {for (final item in user.incomes) item.id: item},
    );
  }
}
