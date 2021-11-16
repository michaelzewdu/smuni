import 'dart:async';

import 'package:smuni/models/models.dart';
import 'package:smuni/providers/cache/cache.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

import 'repositories.dart';

class ApiCategoryRepository extends ApiRepository<String, Category,
    CreateCategoryInput, UpdateCategoryInput> {
  final Cache<String, Category> cache;
  final SmuniApiClient client;

  final StreamController<Set<String>> _changedItemsController =
      StreamController.broadcast();

  ApiCategoryRepository(
    this.cache,
    this.client,
  );

  @override
  Stream<Set<String>> get changedItems => _changedItemsController.stream;

  @override
  Future<Category?> getItem(
    String id,
    String username,
    String authToken,
  ) async {
    var item = await cache.getItem(id);
    if (item != null) return item;
    try {
      item = await client.getCategory(id, username, authToken);
      await cache.setItem(id, item);
      return item;
    } on EndpointError catch (e) {
      if (e.type == "CategoryNotFound") return null;
    }
  }

  @override
  Future<Category> updateItem(
    String id,
    UpdateCategoryInput input,
    String username,
    String authToken,
  ) async {
    final item = await client.updateCategory(id, username, authToken, input);

    await cache.setItem(id, item);
    _changedItemsController.add({id});
    return item;
  }

  @override
  Future<Category> createItem(
    CreateCategoryInput input,
    String username,
    String authToken,
  ) async {
    final item = await client.createCategory(username, authToken, input);

    await cache.setItem(item.id, item);
    _changedItemsController.add({item.id});
    return item;
  }

  @override
  Future<void> removeItem(
    String id,
    String username,
    String authToken, [
    bool bypassChangedItemNotification = false,
  ]) async {
    await client.deleteCategory(id, username, authToken);
    await cache.removeItem(id);
    if (!bypassChangedItemNotification) _changedItemsController.add({id});
  }

  @override
  Future<Map<String, Category>> getItems() => cache.getItems();

  @override
  UpdateCategoryInput updateFromDiff(Category update, Category old) =>
      UpdateCategoryInput.fromDiff(update: update, old: old);

  @override
  CreateCategoryInput createFromItem(Category item) =>
      CreateCategoryInput.fromItem(item);

  @override
  Future<void> refreshCache(Map<String, Category> items) async {
    await cache.clear();
    Set<String> ids = {};
    for (final p in items.entries) {
      ids.add(p.key);
      await cache.setItem(p.key, p.value);
    }
    _changedItemsController.add(ids);
  }
}

class OfflineCategoryRepository extends OfflineRepository<String, Category,
    CreateCategoryInput, UpdateCategoryInput> {
  OfflineCategoryRepository(
    Cache<String, Category> cache,
    Cache<String, Category> serverVersionCache,
    RemovedItemsCache<String> removedItemsCache,
  ) : super(cache, serverVersionCache, removedItemsCache);

  @override
  Pair<String, Category> itemFromCreateInput(CreateCategoryInput input) {
    final id = "offlineId-${DateTime.now().millisecondsSinceEpoch}";
    return Pair(
      id,
      Category(
          id: id,
          version: -1,
          isServerVersion: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          name: input.name,
          tags: input.tags ?? [],
          parentId: input.parentId),
    );
  }

  @override
  Category itemFromUpdateInput(Category item, UpdateCategoryInput input) {
    var category = Category.from(
      item,
      isServerVersion: false,
      name: input.name,
      tags: input.tags ?? item.tags,
      parentId: input.parentId,
    );
    if (category.parentId == "") {
      category.parentId = null;
    }
    if (input.archive != null) {
      if (input.archive! && item.archivedAt == null) {
        category.archivedAt = DateTime.now();
      } else if (!input.archive! && item.archivedAt != null) {
        category.archivedAt = null;
      }
    }
    return category;
  }

  /// this baby gets special treatment because we want to create
  /// parent categories first
  @override
  Future<List<Pair<String, CreateCategoryInput>>> getPendingCreates() async {
    final allItems = await getItemsOffline();
    final createdItems = {
      for (final item in allItems.values.where((e) => e.version == -1)) item.id
    };
    final ancestryGraph =
        CategoryRepositoryExt.calcAncestryTree(createdItems, allItems);
    // collect the root nodes first
    var nodesToProcess = ancestryGraph.values
        .where(
            (e) => e.parent == null || !createdItems.contains(e.parent!.item))
        .toList();
    final pendingCreates = <Pair<String, CreateCategoryInput>>[];
    while (nodesToProcess.isNotEmpty) {
      for (final node in nodesToProcess) {
        pendingCreates.add(
          Pair(node.item, CreateCategoryInput.fromItem(allItems[node.item]!)),
        );
      }
      // collect the immdiate children of the nodes we just processed
      nodesToProcess = [
        ...nodesToProcess
            .map((e) => e.children.map((e) => ancestryGraph[e]!))
            .reduce((v, e) => [...v, ...e])
      ];
    }
    return pendingCreates;
  }

  @override
  Future<Map<String, UpdateCategoryInput>> getPendingUpdates() async => {
        for (final item in (await getItemsOffline())
            .values
            .where((e) => !e.isServerVersion && e.version > -1))
          item.id: UpdateCategoryInput.fromDiff(
              update: item, old: (await serverVersionCache.getItem(item.id))!)
      };

  @override
  bool isServerVersion(Category item) => item.isServerVersion;
}
