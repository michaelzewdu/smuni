import 'dart:async';

import 'package:smuni/models/models.dart';
import 'package:smuni/providers/cache/cache.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

import 'repositories.dart';

class ApiBudgetRepository
    extends ApiRepository<String, Budget, CreateBudgetInput, UpdateBudgetInput>
/* with
        OfflineCapableRepository<String, Budget, CreateBudgetInput,
            UpdateBudgetInput>  */
{
  final Cache<String, Budget> cache;
  // final Cache<String, Budget> serverVersionCache;
  final SmuniApiClient client;

  final StreamController<Set<String>> _changedItemsController =
      StreamController.broadcast();

  ApiBudgetRepository(
    this.client,
    this.cache,
    // this.serverVersionCache,
  );

  @override
  Stream<Set<String>> get changedItems => _changedItemsController.stream;

  @override
  Future<Budget?> getItem(String id, String username, String authToken) async {
    var item = await cache.getItem(id);
    if (item != null) return item;
    try {
      item = await client.getBudget(id, username, authToken);
      await cache.setItem(id, item);
      return item;
    } on EndpointError catch (err) {
      if (err.type == "BudgetNotFound") return null;
    }
  }

  @override
  Future<Budget> updateItem(
    String id,
    UpdateBudgetInput input,
    String username,
    String authToken,
  ) async {
    final item = await client.updateBudget(id, username, authToken, input);
    await cache.setItem(id, item);
    _changedItemsController.add({id});
    return item;
  }

  @override
  Future<Budget> createItem(
    CreateBudgetInput input,
    String username,
    String authToken,
  ) async {
    final item = await client.createBudget(username, authToken, input);
    await cache.setItem(item.id, item);
    _changedItemsController.add({item.id});
    return item;
  }

  @override
  Future<Map<String, Budget>> getItems() => cache.getItems();

  @override
  Future<void> removeItem(
    String id,
    String username,
    String authToken, [
    bool bypassChangedItemNotification = false,
  ]) async {
    await client.deleteBudget(id, username, authToken);
    await cache.removeItem(id);
    if (!bypassChangedItemNotification) _changedItemsController.add({id});
  }

  @override
  UpdateBudgetInput updateFromDiff(Budget update, Budget old) =>
      UpdateBudgetInput.fromDiff(update: update, old: old);

  @override
  CreateBudgetInput createFromItem(Budget item) =>
      CreateBudgetInput.fromItem(item);

  @override
  Future<void> refreshCache(Map<String, Budget> items) async {
    await cache.clear();
    Set<String> ids = {};
    for (final p in items.entries) {
      ids.add(p.key);
      await cache.setItem(p.key, p.value);
    }
    _changedItemsController.add(ids);
  }

  /*  @override
  Future<Budget> createItemOffline(String id, Budget input) {
    // TODO: implement createItemOffline
    throw UnimplementedError();
  }

  @override
  Future<void> removeItemOffline(String id) {
    // TODO: implement removeItemOffline
    throw UnimplementedError();
  }

  @override
  Future<Budget> updateItemOffline(
      String id, Budget update, String username, String authToken) {
    // TODO: implement updateItemOffline
    throw UnimplementedError();
  } */
}

class OfflineBudgetRepository extends OfflineRepository<String, Budget,
    CreateBudgetInput, UpdateBudgetInput> {
  OfflineBudgetRepository(
    Cache<String, Budget> cache,
    Cache<String, Budget> serverVersionCache,
    RemovedItemsCache<String> removedItemsCache,
  ) : super(cache, serverVersionCache, removedItemsCache);

  @override
  Pair<String, Budget> itemFromCreateInput(CreateBudgetInput input) {
    final id = "offlineId-${DateTime.now().millisecondsSinceEpoch}";
    return Pair(
      id,
      Budget(
        id: id,
        version: -1,
        isServerVersion: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        name: input.name,
        startTime: input.startTime,
        endTime: input.endTime,
        allocatedAmount: input.allocatedAmount,
        frequency: input.frequency,
        categoryAllocations: input.categoryAllocations,
      ),
    );
  }

  @override
  Budget itemFromUpdateInput(Budget item, UpdateBudgetInput input) {
    var budget = Budget.from(
      item,
      isServerVersion: false,
      name: input.name,
      startTime: input.startTime,
      endTime: input.endTime,
      allocatedAmount: input.allocatedAmount,
      frequency: input.frequency,
      categoryAllocations: input.categoryAllocations,
    );
    if (input.archive != null) {
      if (input.archive! && item.archivedAt == null) {
        budget.archivedAt = DateTime.now();
      } else if (!input.archive! && item.archivedAt != null) {
        budget.archivedAt = null;
      }
    }
    return budget;
  }

  @override
  Future<List<Pair<String, CreateBudgetInput>>> getPendingCreates() async => [
        for (final item
            in (await getItemsOffline()).values.where((e) => e.version == -1))
          Pair(item.id, CreateBudgetInput.fromItem(item))
      ];

  @override
  Future<Map<String, UpdateBudgetInput>> getPendingUpdates() async => {
        for (final item in (await getItemsOffline())
            .values
            .where((e) => !e.isServerVersion && e.version > -1))
          item.id: UpdateBudgetInput.fromDiff(
              update: item, old: (await serverVersionCache.getItem(item.id))!)
      };

  @override
  bool isServerVersion(Budget item) => item.isServerVersion;
}
