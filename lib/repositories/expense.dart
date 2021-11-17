import 'dart:async';

import 'package:smuni/models/models.dart';
import 'package:smuni/providers/cache/cache.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

import 'repositories.dart';

class ApiExpenseRepository extends ApiRepository<String, Expense,
    CreateExpenseInput, UpdateExpenseInput> {
  final Cache<String, Expense> cache;
  final SmuniApiClient client;
  final StreamController<Set<String>> _changedItemsController =
      StreamController.broadcast();

  ApiExpenseRepository(this.cache, this.client);

  @override
  Stream<Set<String>> get changedItems => _changedItemsController.stream;

  @override
  Future<Expense?> getItem(String id, String username, String authToken) async {
    var item = await cache.getItem(id);
    if (item != null) return item;
    try {
      item = await client.getExpense(id, username, authToken);
      await cache.setItem(id, item);
      return item;
    } on EndpointError catch (e) {
      if (e.type == "ExpenseNotFound") return null;
      rethrow;
    }
  }

  @override
  Future<Expense> updateItem(String id, UpdateExpenseInput input,
      String username, String authToken) async {
    final item = await client.updateExpense(id, username, authToken, input);

    await cache.setItem(id, item);
    _changedItemsController.add({id});
    return item;
  }

  @override
  Future<Expense> createItem(
    CreateExpenseInput input,
    String username,
    String authToken,
  ) async {
    final item = await client.createExpense(username, authToken, input);

    await cache.setItem(item.id, item);
    _changedItemsController.add({item.id});
    return item;
  }

  @override
  Future<Map<String, Expense>> getItems() => cache.getItems();

  @override
  Future<void> removeItem(
    String id,
    String username,
    String authToken, [
    bool bypassChangedItemNotification = false,
  ]) async {
    await client.deleteExpense(id, username, authToken);
    await cache.removeItem(id);
    if (!bypassChangedItemNotification) _changedItemsController.add({id});
  }

  @override
  UpdateExpenseInput updateFromDiff(Expense update, Expense old) =>
      UpdateExpenseInput.fromDiff(update: update, old: old);

  @override
  CreateExpenseInput createFromItem(Expense item) =>
      CreateExpenseInput.fromItem(item);

  @override
  bool isEmptyUpdate(UpdateExpenseInput input) => input.isEmpty;

  @override
  Future<void> refreshCache(Map<String, Expense> items) async {
    await cache.clear();
    Set<String> ids = {};
    for (final p in items.entries) {
      ids.add(p.key);
      await cache.setItem(p.key, p.value);
    }
    _changedItemsController.add(ids);
  }
}

class OfflineExpenseRepository extends OfflineRepository<String, Expense,
    CreateExpenseInput, UpdateExpenseInput> {
  OfflineExpenseRepository(
    Cache<String, Expense> cache,
    Cache<String, Expense> serverVersionCache,
    RemovedItemsCache<String> removedItemsCache,
  ) : super(cache, serverVersionCache, removedItemsCache);

  @override
  Pair<String, Expense> itemFromCreateInput(CreateExpenseInput input) {
    final id = "offlineId-${DateTime.now().millisecondsSinceEpoch}";
    return Pair(
      id,
      Expense(
        id: id,
        version: -1,
        isServerVersion: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        name: input.name,
        timestamp: input.timestamp ?? DateTime.now(),
        categoryId: input.categoryId,
        budgetId: input.budgetId,
        amount: input.amount,
      ),
    );
  }

  @override
  Expense itemFromUpdateInput(Expense item, UpdateExpenseInput input) =>
      Expense.from(
        item,
        name: input.name,
        isServerVersion: false,
        timestamp: input.timestamp,
        amount: input.amount,
        budgetId: input.budgetAndCategoryId?.a,
        categoryId: input.budgetAndCategoryId?.b,
      );

  @override
  Future<List<Pair<String, CreateExpenseInput>>> getPendingCreates() async => [
        for (final item
            in (await getItemsOffline()).values.where((e) => e.version == -1))
          Pair(item.id, CreateExpenseInput.fromItem(item))
      ];
  @override
  Future<Map<String, UpdateExpenseInput>> getPendingUpdates() async => {
        for (final item in (await getItemsOffline())
            .values
            .where((e) => !e.isServerVersion && e.version > -1))
          item.id: UpdateExpenseInput.fromDiff(
              update: item, old: (await serverVersionCache.getItem(item.id))!)
      };

  @override
  bool isServerVersion(Expense item) => item.isServerVersion;
}
