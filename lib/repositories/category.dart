import 'dart:async';

import 'package:smuni/models/models.dart';
import 'package:smuni/providers/cache/cache.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

import 'auth.dart';
import 'repositories.dart';

class ApiCategoryRepository extends Repository<String, Category,
    CreateCategoryInput, UpdateCategoryInput> {
  final Cache<String, Category> cache;
  final SmuniApiClient client;
  final AuthTokenRepository tokenRepo;

  final StreamController<Set<String>> _changedItemsController =
      StreamController.broadcast();

  ApiCategoryRepository(this.cache, this.client, this.tokenRepo);

  @override
  Stream<Set<String>> get changedItems => _changedItemsController.stream;

  @override
  Future<Category?> getItem(String id) async {
    var item = await cache.getItem(id);
    if (item != null) return item;
    try {
      final token = await tokenRepo.accessToken;
      item = await client.getCategory(id, tokenRepo.username, token);
      await cache.setItem(id, item);
      return item;
    } on EndpointError catch (e) {
      if (e.type == "CategoryNotFound") return null;
    }
  }

  @override
  Future<Category> updateItem(String id, UpdateCategoryInput input) async {
    if (input.isEmpty) {
      final old = await getItem(id);
      if (old == null) throw ItemNotFoundException(id);
      return old;
    }

    final token = await tokenRepo.accessToken;
    final item =
        await client.updateCategory(id, tokenRepo.username, token, input);

    await cache.setItem(id, item);
    _changedItemsController.add({id});
    return item;
  }

  @override
  Future<Category> createItem(CreateCategoryInput input, [String? id]) async {
    final token = await tokenRepo.accessToken;
    final item = await client.createCategory(tokenRepo.username, token, input);

    await cache.setItem(item.id, item);
    _changedItemsController.add({item.id});
    return item;
  }

  Future<void> deleteItem(
    String id,
  ) async {
    final token = await tokenRepo.accessToken;
    await client.deleteCategory(
      id,
      tokenRepo.username,
      token,
    );
    await cache.removeItem(id);
    _changedItemsController.add({id});
  }

  @override
  Future<Map<String, Category>> getItems() => cache.getItems();

  @override
  Future<void> removeItem(
    String id, [
    bool bypassChangedItemNotification = false,
  ]) async {
    final token = await tokenRepo.accessToken;
    await client.deleteCategory(
      id,
      tokenRepo.username,
      token,
    );
    await cache.removeItem(id);
    if (!bypassChangedItemNotification) _changedItemsController.add({id});
  }

  @override
  UpdateCategoryInput updateFromDiff(Category update, Category old) {
    return UpdateCategoryInput.fromDiff(update: update, old: old);
  }

  @override
  CreateCategoryInput createFromItem(Category item) => CreateCategoryInput(
        name: item.name,
        parentId: item.parentId,
        tags: item.tags,
      );

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
