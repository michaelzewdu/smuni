import 'dart:async';

import 'package:smuni/models/models.dart';
import 'package:smuni/providers/cache/cache.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

import 'auth.dart';
import 'repositories.dart';

class ApiUserRepository
    extends Repository<String, User, CreateUserInput, UpdateUserInput> {
  final Cache<String, User> cache;
  final SmuniApiClient client;
  final AuthTokenRepository tokenRepo;

  final StreamController<Set<String>> _changedItemsController =
      StreamController.broadcast();

  @override
  Stream<Set<String>> get changedItems => _changedItemsController.stream;

  ApiUserRepository(this.cache, this.client, this.tokenRepo);

  @override
  // ignore: avoid_renaming_method_parameters
  Future<User?> getItem(String username) async {
    var user = await cache.getItem(username);
    if (user != null) return user;
    try {
      final token = await tokenRepo.accessToken;
      user = User.from(await client.getUser(username, token));
      await cache.setItem(username, user);
      return user;
    } on EndpointError catch (e) {
      if (e.type == "UserNotFound") return null;
      rethrow;
    }
  }

  @override
  Future<User> updateItem(String id, UpdateUserInput input) async {
    if (input.isEmpty) {
      final old = await getItem(id);
      if (old == null) throw ItemNotFoundException(id);
      return old;
    }

    final token = await tokenRepo.accessToken;
    final item = User.from(await client.updateUser(id, token, input));
    await cache.setItem(id, item);
    _changedItemsController.add({id});
    return item;
  }

  @override
  Future<User> createItem(CreateUserInput input, [String? id]) {
    // TODO: implement createItem
    throw UnimplementedError();
  }

  @override
  Future<Map<String, User>> getItems() {
    // TODO: implement getItems
    throw UnimplementedError();
  }

  @override
  Future<void> removeItem(
    String id, [
    bool bypassChangedItemNotification = false,
  ]) {
    // TODO: implement removeItem
    throw UnimplementedError();
  }

  @override
  UpdateUserInput updateFromDiff(User update, User old) {
    return UpdateUserInput.fromDiff(update: update, old: old);
  }

  @override
  CreateUserInput createFromItem(User item) {
    // TODO: implement removeItem
    throw UnimplementedError();
  }

  @override
  Future<void> refreshCache(Map<String, User> items) async {
    await cache.clear();
    Set<String> ids = {};
    for (final p in items.entries) {
      ids.add(p.key);
      await cache.setItem(p.key, p.value);
    }
    _changedItemsController.add(ids);
  }
}
