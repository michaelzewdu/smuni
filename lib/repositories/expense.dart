import 'dart:async';

import 'package:smuni/models/models.dart';
import 'package:smuni/providers/cache/cache.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

import 'auth.dart';
import 'repositories.dart';

class ApiExpenseRepository extends Repository<String, Expense,
    CreateExpenseInput, UpdateExpenseInput> {
  final Cache<String, Expense> cache;
  final SmuniApiClient client;
  final AuthTokenRepository tokenRepo;

  final StreamController<Set<String>> _changedItemsController =
      StreamController.broadcast();

  ApiExpenseRepository(this.cache, this.client, this.tokenRepo);

  @override
  Stream<Set<String>> get changedItems => _changedItemsController.stream;

  @override
  Future<Expense?> getItem(String id) async {
    var item = await cache.getItem(id);
    if (item != null) return item;
    try {
      final token = await tokenRepo.accessToken;
      item = await client.getExpense(id, tokenRepo.username, token);
      await cache.setItem(id, item);
      return item;
    } catch (e) {
      if (e is EndpointError && e.type == "ExpenseNotFound") return null;
      rethrow;
    }
  }

  @override
  Future<Expense> updateItem(String id, UpdateExpenseInput input) async {
    if (input.isEmpty) {
      final old = await getItem(id);
      if (old == null) throw ItemNotFoundException(id);
      return old;
    }

    final token = await tokenRepo.accessToken;
    final item =
        await client.updateExpense(id, tokenRepo.username, token, input);

    await cache.setItem(id, item);
    _changedItemsController.add({id});
    return item;
  }

  @override
  Future<Expense> createItem(CreateExpenseInput input, [String? id]) async {
    final token = await tokenRepo.accessToken;
    final item = await client.createExpense(tokenRepo.username, token, input);

    await cache.setItem(item.id, item);
    _changedItemsController.add({item.id});
    return item;
  }

  Future<void> deleteItem(
    String id,
  ) async {
    final token = await tokenRepo.accessToken;
    await client.deleteExpense(
      id,
      tokenRepo.username,
      token,
    );
    await cache.removeItem(id);
    _changedItemsController.add({id});
  }

  @override
  Future<Map<String, Expense>> getItems() => cache.getItems();

  @override
  Future<void> removeItem(String id) async {
    final token = await tokenRepo.accessToken;
    await client.deleteExpense(
      id,
      tokenRepo.username,
      token,
    );
    await cache.removeItem(id);
    _changedItemsController.add({id});
  }

  @override
  UpdateExpenseInput updateFromDiff(Expense update, Expense old) {
    return UpdateExpenseInput.fromDiff(update: update, old: old);
  }

  Future<Map<DateRange, DateRangeFilter>> getDateRangeFilters({
    Set<String>? ofExpenses,
    Set<String>? ofCategories,
  }) async {
    final items = await getItems();
    return generateDateRangesFilters(
      items.values
          .where(ofExpenses != null && ofCategories != null
              ? (e) =>
                  ofExpenses.contains(e.budgetId) &&
                  ofCategories.contains(e.categoryId)
              : ofExpenses != null
                  ? (e) => ofExpenses.contains(e.budgetId)
                  : ofCategories != null
                      ? (e) => ofCategories.contains(e.categoryId)
                      : (e) => true)
          .map((e) => e.createdAt),
    );
  }

  Future<Iterable<Expense>> getItemsInRange(
    DateRange range, {
    Set<String>? ofExpenses,
    Set<String>? ofCategories,
  }) async {
    final items = await getItems();
    return items.values.where(
      ofExpenses != null && ofCategories != null
          ? (e) =>
              range.containsTimestamp(e.createdAt) &&
              ofExpenses.contains(e.budgetId) &&
              ofCategories.contains(e.categoryId)
          : ofExpenses != null
              ? (e) =>
                  range.containsTimestamp(e.createdAt) &&
                  ofExpenses.contains(e.budgetId)
              : ofCategories != null
                  ? (e) =>
                      range.containsTimestamp(e.createdAt) &&
                      ofCategories.contains(e.categoryId)
                  : (e) => range.containsTimestamp(e.createdAt),
    );
  }
}
