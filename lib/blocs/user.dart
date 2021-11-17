// FIXME:

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:smuni/blocs/auth.dart';

import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

// EVENTS

abstract class UserEvent {
  const UserEvent();
}

class LoadUser extends UserEvent with StatusAwareEvent {
  LoadUser({
    OperationSuccessNotifier? onSuccess,
    OperationExceptionNotifier? onError,
  }) {
    this.onSuccess = onSuccess;
    this.onError = onError;
  }
}

class UpdateUser extends UserEvent with StatusAwareEvent {
  final User update;
  final String? newPassword;

  UpdateUser(
    this.update, {
    this.newPassword,
    OperationSuccessNotifier? onSuccess,
    OperationExceptionNotifier? onError,
  }) {
    this.onSuccess = onSuccess;
    this.onError = onError;
  }

  @override
  String toString() => "${runtimeType.toString()} { update: $update }";
}

// STATE

abstract class UserBlocState {
  const UserBlocState();
}

class UserLoading extends UserBlocState {}

class UserLoadSuccess extends UserBlocState {
  final User item;

  const UserLoadSuccess(this.item);

  @override
  String toString() => "${runtimeType.toString()} { item: $item }";
}

// BLOC

class UserBloc extends Bloc<UserEvent, UserBlocState> {
  final AuthBloc authBloc;
  final UserRepository repo;
  UserBloc(this.repo, this.authBloc) : super(UserLoading()) {
    on<UpdateUser>(
      streamToEmitterAdapterStatusAware(_mapUpdateUserEventToState),
    );
    on<LoadUser>(
      streamToEmitterAdapterStatusAware(_mapLoadUserEventToState),
    );

    add(LoadUser());
  }

  Stream<UserBlocState> _mapLoadUserEventToState(LoadUser event) async* {
    try {
      final auth = authBloc.authSuccesState();
      final item = await repo.getItem(auth.username, auth.authToken);
      yield UserLoadSuccess(item!);
    } on SocketException catch (err) {
      throw ConnectionException(err);
    }
  }

  Stream<UserBlocState> _mapUpdateUserEventToState(UpdateUser event) async* {
    final current = state;
    if (current is UserLoadSuccess) {
      try {
        final auth = authBloc.authSuccesState();
        final updated = await repo.updateItem(
          repo.updateFromDiff(event.update, current.item, event.newPassword),
          auth.username,
          auth.authToken,
        );
        yield UserLoadSuccess(updated);
      } on SocketException catch (err) {
        throw ConnectionException(err);
      } on UnseenVersionsFoundError catch (_) {
        throw UnseenVersionException();
      }
    } else {
      throw Exception("impossible event");
    }
  }
}
