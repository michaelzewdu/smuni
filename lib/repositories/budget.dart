import 'dart:async';

import 'package:smuni/models/models.dart';
import 'package:smuni/providers/cache/cache.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

import 'auth.dart';
import 'repositories.dart';

class ApiBudgetRepository
    extends Repository<String, Budget, CreateBudgetInput, UpdateBudgetInput> {
  final Cache<String, Budget> cache;
  final SmuniApiClient client;
  final AuthTokenRepository tokenRepo;

  final StreamController<Set<String>> _changedItemsController =
      StreamController.broadcast();

  ApiBudgetRepository(this.cache, this.client, this.tokenRepo);

  @override
  Stream<Set<String>> get changedItems => _changedItemsController.stream;

  @override
  Future<Budget?> getItem(String id) async {
    var item = await cache.getItem(id);
    if (item != null) return item;
    try {
      final token = await tokenRepo.accessToken;
      item = await client.getBudget(id, tokenRepo.username, token);
      await cache.setItem(id, item);
      return item;
    } on EndpointError catch (err) {
      if (err.type == "BudgetNotFound") return null;
    }
  }

  @override
  Future<Budget> updateItem(String id, UpdateBudgetInput input) async {
    if (input.isEmpty) {
      final old = await getItem(id);
      if (old == null) throw ItemNotFoundException(id);
      return old;
    }

    final token = await tokenRepo.accessToken;
    final item =
        await client.updateBudget(id, tokenRepo.username, token, input);

    await cache.setItem(id, item);
    _changedItemsController.add({id});
    return item;
  }

  @override
  Future<Budget> createItem(CreateBudgetInput input, [String? id]) async {
    final token = await tokenRepo.accessToken;
    final item = await client.createBudget(tokenRepo.username, token, input);

    await cache.setItem(item.id, item);
    _changedItemsController.add({item.id});
    return item;
  }

  Future<void> deleteItem(
    String id,
  ) async {
    final token = await tokenRepo.accessToken;
    await client.deleteBudget(
      id,
      tokenRepo.username,
      token,
    );
    await cache.removeItem(id);
    _changedItemsController.add({id});
  }

  @override
  Future<Map<String, Budget>> getItems() => cache.getItems();

  @override
  Future<void> removeItem(String id) async {
    final token = await tokenRepo.accessToken;
    await client.deleteBudget(
      id,
      tokenRepo.username,
      token,
    );
    await cache.removeItem(id);
    _changedItemsController.add({id});
  }

  @override
  UpdateBudgetInput updateFromDiff(Budget update, Budget old) {
    return UpdateBudgetInput.fromDiff(update: update, old: old);
  }

  @override
  CreateBudgetInput createFromItem(Budget item) => CreateBudgetInput(
        name: item.name,
        startTime: item.startTime,
        endTime: item.endTime,
        frequency: item.frequency,
        allocatedAmount: item.allocatedAmount,
        categoryAllocations: item.categoryAllocations,
      );
}
