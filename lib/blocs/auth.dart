import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:jwt_decode/jwt_decode.dart';

import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

// EVENTS

abstract class AuthBlocEvent {
  const AuthBlocEvent();
}

enum SignInMethod { email, phoneNumber, username }

class CheckCache extends AuthBlocEvent {}

class CredentialsRejected implements OperationException {}

class SignIn extends AuthBlocEvent with StatusAwareEvent {
  final SignInMethod method;
  final String identifier;
  final String password;

  SignIn({
    required this.method,
    required this.identifier,
    required this.password,
    OperationSuccessNotifier? onSuccess,
    OperationExceptionNotifier? onError,
  }) {
    this.onSuccess = onSuccess;
    this.onError = onError;
  }

  @override
  String toString() =>
      "${runtimeType.toString()} { method: $method, identifier: $identifier, password: <redacted> }";
}

class SignOut extends AuthBlocEvent {}
// STATE

abstract class AuthBlocState {
  const AuthBlocState();
}

class Unauthenticated extends AuthBlocState {}

class AuthSuccess extends AuthBlocState {
  final String authToken;
  final String username;

  AuthSuccess({required this.authToken, required this.username});
  @override
  String toString() =>
      "${runtimeType.toString()} { authToken: <redacted>, username: $username }";
}

// BLOC

class AuthBloc extends Bloc<AuthBlocEvent, AuthBlocState> {
  final AuthRepository repo;
  final CacheSynchronizer synchronizer;

  AuthBloc(this.repo, this.synchronizer) : super(Unauthenticated()) {
    on<SignOut>(
      streamToEmitterAdapter(_handleLogout),
    );
    on<SignIn>(
      streamToEmitterAdapterStatusAware(_handleLogin),
    );
    on<CheckCache>(
      streamToEmitterAdapter(_handleCheckCache),
    );
  }

  AuthSuccess authSuccesState() {
    final current = state;
    if (current is! AuthSuccess) throw UnauthenticatedException();
    return current;
  }

  Stream<AuthBlocState> _handleLogin(SignIn event) async* {
    try {
      SignInResponse response;
      switch (event.method) {
        case SignInMethod.email:
          response = await repo.signInEmail(event.identifier, event.password);
          break;
        case SignInMethod.phoneNumber:
          response = await repo.signInPhone(event.identifier, event.password);
          break;
        case SignInMethod.username:
          response =
              await repo.signInUsername(event.identifier, event.password);
          break;
        default:
          throw Exception("Unexpected enum: ${event.method}");
      }
      await synchronizer.refreshFromUser(response.user);
      yield AuthSuccess(
          authToken: response.accessToken, username: response.user.username);
    } on SocketException catch (err) {
      throw ConnectionException(err);
    } on EndpointError catch (err) {
      if (err.code == 400 && err.type == "CredentialsRejected") {
        throw CredentialsRejected();
      } else {
        rethrow;
      }
    }
  }

  Stream<AuthBlocState> _handleLogout(SignOut event) async* {
    await repo.clearCache();
    yield Unauthenticated();
  }

  Stream<AuthBlocState> _handleCheckCache(CheckCache event) async* {
    final username = await repo.tryGetLoggedInUsername();
    final token = await repo.tryGetAccessToken();

    if (token != null && username != null) {
      if (!Jwt.isExpired(token)) {
        yield AuthSuccess(username: username, authToken: token);
      } else {
        // sign out if access token expired
        await repo.clearCache();
        yield Unauthenticated();
      }
    } else {
      yield Unauthenticated();
    }
  }
}
