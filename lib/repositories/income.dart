import 'dart:async';

import 'package:smuni/models/models.dart';
import 'package:smuni/providers/cache/cache.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

import 'repositories.dart';

class ApiIncomeRepository extends ApiRepository<String, Income,
    CreateIncomeInput, UpdateIncomeInput> {
  final Cache<String, Income> cache;
  final SmuniApiClient client;
  final StreamController<Set<String>> _changedItemsController =
      StreamController.broadcast();

  ApiIncomeRepository(this.cache, this.client);

  @override
  Stream<Set<String>> get changedItems => _changedItemsController.stream;

  @override
  Future<Income?> getItem(String id, String username, String authToken) async {
    var item = await cache.getItem(id);
    if (item != null) return item;
    try {
      item = await client.getIncome(id, username, authToken);
      await cache.setItem(id, item);
      return item;
    } on EndpointError catch (e) {
      if (e.type == "IncomeNotFound") return null;
      rethrow;
    }
  }

  @override
  Future<Income> updateItem(String id, UpdateIncomeInput input, String username,
      String authToken) async {
    final item = await client.updateIncome(id, username, authToken, input);

    await cache.setItem(id, item);
    _changedItemsController.add({id});
    return item;
  }

  @override
  Future<Income> createItem(
    CreateIncomeInput input,
    String username,
    String authToken,
  ) async {
    final item = await client.createIncome(username, authToken, input);

    await cache.setItem(item.id, item);
    _changedItemsController.add({item.id});
    return item;
  }

  @override
  Future<Map<String, Income>> getItems() => cache.getItems();

  @override
  Future<void> removeItem(
    String id,
    String username,
    String authToken, [
    bool bypassChangedItemNotification = false,
  ]) async {
    await client.deleteIncome(id, username, authToken);
    await cache.removeItem(id);
    if (!bypassChangedItemNotification) _changedItemsController.add({id});
  }

  @override
  UpdateIncomeInput updateFromDiff(Income update, Income old) =>
      UpdateIncomeInput.fromDiff(update: update, old: old);

  @override
  CreateIncomeInput createFromItem(Income item) =>
      CreateIncomeInput.fromItem(item);

  @override
  bool isEmptyUpdate(UpdateIncomeInput input) => input.isEmpty;

  @override
  Future<void> refreshCache(Map<String, Income> items) async {
    await cache.clear();
    Set<String> ids = {};
    for (final p in items.entries) {
      ids.add(p.key);
      await cache.setItem(p.key, p.value);
    }
    _changedItemsController.add(ids);
  }
}

class OfflineIncomeRepository extends OfflineRepository<String, Income,
    CreateIncomeInput, UpdateIncomeInput> {
  OfflineIncomeRepository(
    Cache<String, Income> cache,
    Cache<String, Income> serverVersionCache,
    RemovedItemsCache<String> removedItemsCache,
  ) : super(cache, serverVersionCache, removedItemsCache);

  @override
  Pair<String, Income> itemFromCreateInput(CreateIncomeInput input) {
    final id = "offlineId-${DateTime.now().millisecondsSinceEpoch}";
    return Pair(
      id,
      Income(
        id: id,
        version: -1,
        isServerVersion: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        name: input.name,
        timestamp: input.timestamp ?? DateTime.now(),
        frequency: input.frequency,
        amount: input.amount,
      ),
    );
  }

  @override
  Income itemFromUpdateInput(Income item, UpdateIncomeInput input) =>
      Income.from(
        item,
        name: input.name,
        isServerVersion: false,
        timestamp: input.timestamp,
        amount: input.amount,
        frequency: input.frequency,
      );

  @override
  Future<List<Pair<String, CreateIncomeInput>>> getPendingCreates() async => [
        for (final item
            in (await getItemsOffline()).values.where((e) => e.version == -1))
          Pair(item.id, CreateIncomeInput.fromItem(item))
      ];
  @override
  Future<Map<String, UpdateIncomeInput>> getPendingUpdates() async => {
        for (final item in (await getItemsOffline())
            .values
            .where((e) => !e.isServerVersion && e.version > -1))
          item.id: UpdateIncomeInput.fromDiff(
              update: item, old: (await serverVersionCache.getItem(item.id))!)
      };

  @override
  bool isServerVersion(Income item) => item.isServerVersion;
}
