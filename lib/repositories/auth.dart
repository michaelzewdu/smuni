import 'dart:async';

import 'package:jwt_decode/jwt_decode.dart';

import 'package:smuni/providers/cache/cache.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

class RefreshTokenExpiredException implements Exception {}

class CacheEmptyException implements Exception {}

class AuthTokenRepository {
  final SmuniApiClient client;
  final AuthTokenCache cache;

  String _username;

  String get username => _username;

  set username(String username) {
    cache.setUsername(username);
    _username = username;
  }

  String _accessToken;
  String _refreshToken;

  Future<String> get accessToken async {
    if (Jwt.isExpired(_accessToken)) {
      await _refreshAccessToken();
    }
    return _accessToken;
  }

  Future<void> _refreshAccessToken() async {
    // TODO: _refreshAccessToken
    if (Jwt.isExpired(_refreshToken)) throw RefreshTokenExpiredException();
    throw UnimplementedError();
  }

  AuthTokenRepository._(
    this.client,
    this.cache, {
    required String accessToken,
    required String refreshToken,
    required String username,
  })  : assert(!Jwt.isExpired(accessToken)),
        assert(!Jwt.isExpired(refreshToken)),
        _username = username,
        _accessToken = accessToken,
        _refreshToken = refreshToken;

  static Future<AuthTokenRepository> fromCache(
    SmuniApiClient client,
    AuthTokenCache cache,
  ) async {
    final accessToken = await cache.getAccessToken();
    if (accessToken == null) throw CacheEmptyException();
    final refreshToken = await cache.getRefreshToken();
    if (refreshToken == null) throw CacheEmptyException();
    final username = await cache.getUsername();
    if (username == null) throw CacheEmptyException();

    return AuthTokenRepository._(
      client,
      cache,
      accessToken: accessToken,
      refreshToken: refreshToken,
      username: username,
    );
  }

  /// This will immediately override any values in the cache.
  static Future<AuthTokenRepository> fromValues({
    required SmuniApiClient client,
    required AuthTokenCache cache,
    required String accessToken,
    required String refreshToken,
    required String loggedInUsername,
  }) async {
    // create repo first to run assertions
    final repo = AuthTokenRepository._(
      client,
      cache,
      accessToken: accessToken,
      refreshToken: refreshToken,
      username: loggedInUsername,
    );

    await cache.setAccessToken(accessToken);
    await cache.setRefreshToken(refreshToken);
    await cache.setUsername(loggedInUsername);

    return repo;
  }
}
