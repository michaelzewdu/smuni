import 'dart:async';

import 'package:smuni/models/models.dart';
import 'package:smuni/providers/cache/cache.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

class ApiUserRepository {
  final Cache<String, User> cache;
  final SmuniApiClient client;

  final StreamController<Set<String>> _changedItemsController =
      StreamController.broadcast();

  Stream<Set<String>> get changedItems => _changedItemsController.stream;

  ApiUserRepository(this.cache, this.client);

  Future<void> refreshCache(Map<String, User> items) async {
    await cache.clear();
    Set<String> ids = {};
    for (final p in items.entries) {
      ids.add(p.key);
      await cache.setItem(p.key, p.value);
    }
    _changedItemsController.add(ids);
  }

  Future<User?> getItem(String username, String authToken) async {
    var user = await cache.getItem(username);
    if (user != null) return user;
    try {
      user = User.from(await client.getUser(username, authToken));
      await cache.setItem(username, user);
      return user;
    } on EndpointError catch (e) {
      if (e.type == "UserNotFound") return null;
      rethrow;
    }
  }

  Future<User?> getItemFromCache(String username) => cache.getItem(username);

  UpdateUserInput updateFromDiff(User update, User old, [String? password]) =>
      UpdateUserInput.fromDiff(update: update, old: old, password: password);

  Future<UserDenorm> updateItem(
    UpdateUserInput input,
    String username,
    String authToken,
  ) async {
    final item = await client.updateUser(username, authToken, input);
    await cache.setItem(username, User.from(item));
    _changedItemsController.add({username});
    return item;
  }

  Future<void> createUser(
      {required String firebaseId,
      required String phoneNo,
      required String email,
      required String password,
      required String username}) async {
    final newUser = CreateUserInput(
      firebaseId: firebaseId,
      username: username,
      email: email,
      phoneNumber: phoneNo,
      password: password,
    );

    final item = await client.createUser(newUser);
    await cache.setItem(username, User.from(item));
    _changedItemsController.add({username});
    // return item;
  }
}
