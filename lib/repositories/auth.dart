import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:smuni/providers/cache/cache.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

class RefreshTokenExpiredException implements Exception {}

class CacheEmptyException implements Exception {}

class AuthRepository {
  final SmuniApiClient client;
  final AuthTokenCache cache;
  String thisVerificationId = '';

  Future<SignInResponse> signInUsername(
    String username,
    String password,
  ) async {
    final response = await client.signInUsername(username, password);
    await refreshFromValues(
      accessToken: response.accessToken,
      loggedInUsername: response.user.username,
      refreshToken: response.refreshToken,
    );
    return response;
  }

  Future<SignInResponse> signInEmail(
    String email,
    String password,
  ) async {
    final response = await client.signInEmail(email, password);
    await refreshFromValues(
      accessToken: response.accessToken,
      loggedInUsername: response.user.username,
      refreshToken: response.refreshToken,
    );
    return response;
  }

  Future<SignInResponse> signInPhone(
    String phoneNumber,
    String password,
  ) async {
    final response = await client.signInPhone(phoneNumber, password);
    await refreshFromValues(
      accessToken: response.accessToken,
      loggedInUsername: response.user.username,
      refreshToken: response.refreshToken,
    );
    return response;
  }

  Future<SignInResponse> signInFirebaseId(
    String firebaseId,
    String password,
  ) async {
    final response = await client.signInFirebaseId(firebaseId, password);
    await refreshFromValues(
      accessToken: response.accessToken,
      loggedInUsername: response.user.username,
      refreshToken: response.refreshToken,
    );
    return response;
  }

  Future<String> getLoggedInUsername() async {
    final username = await cache.getUsername();
    if (username == null) throw CacheEmptyException();
    return username;
  }

  Future<String> getAccessToken() async {
    final token = await cache.getAccessToken();
    if (token == null) throw CacheEmptyException();
    return token;
  }

  Future<String?> tryGetLoggedInUsername() => cache.getUsername();

  Future<String?> tryGetAccessToken() async {
    var token = await cache.getAccessToken();
    if (token != null) {
      if (Jwt.isExpired(token)) {
        final refreshToken = await cache.getRefreshToken();
        if (refreshToken == null || Jwt.isExpired(refreshToken)) {
          throw RefreshTokenExpiredException();
        }
        // TODO: _refreshAccessToken
        throw UnimplementedError();
      }
    }
    return token;
  }

  AuthRepository(this.client, this.cache);

  /// This will immediately override any values in the cache.
  Future<void> refreshFromValues({
    required String accessToken,
    required String refreshToken,
    required String loggedInUsername,
  }) async {
    await cache.setAccessToken(accessToken);
    await cache.setRefreshToken(refreshToken);
    await cache.setUsername(loggedInUsername);
  }

  Future<void> clearCache() async {
    await cache.clearAccessToken();
    await cache.clearRefreshToken();
    await cache.clearUsername();
  }

  void firebaseCodeSent(
      {String? verificationId,
      int? resendToken,
      String? otpCode,
      FirebaseAuth? firebaseAuth}) async {
    if (otpCode != null) {
      String smsCode = otpCode;

      // Create a PhoneAuthCredential with the code
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: thisVerificationId, smsCode: smsCode);

      // Sign the user in (or link) with the credential
      await firebaseAuth!.signInWithCredential(credential);
    }
  }

  Future<void> authenticatePhoneNumber(
      String phoneNo, FirebaseAuth firebaseAuth) async {
    await firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNo,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // ANDROID ONLY!

          // Sign the user in (or link) with the auto-generated credential
          await firebaseAuth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('The firebase error is: ${e.code}');
          throw (MyFirebaseError(e.code));
        },
        codeSent: (String verificationId, int? resendToken) async {
          thisVerificationId = verificationId;
        },
        codeAutoRetrievalTimeout: (String verificationId) {});
  }
}

class MyFirebaseError implements Exception {
  String cause;
  MyFirebaseError(this.cause);
}
