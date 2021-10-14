// FIXME:

import 'dart:async';
import 'package:bloc/bloc.dart';

import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

// EVENTS

abstract class UserEvent {
  const UserEvent();
}

class LoadUser extends UserEvent with StatusAwareEvent {
  final String id;
  LoadUser(
    this.id, {
    OperationSuccessNotifier? onSuccess,
    OperationExceptionNotifier? onError,
  }) {
    this.onSuccess = onSuccess;
    this.onError = onError;
  }

  @override
  String toString() => "${runtimeType.toString()} { id: $id }";
}

class UpdateUser extends UserEvent with StatusAwareEvent {
  final User update;

  UpdateUser(
    this.update, {
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

class UserLoading extends UserBlocState {
  final String id;

  const UserLoading(this.id);

  @override
  String toString() => "${runtimeType.toString()} { id: $id }";
}

class UserLoadSuccess extends UserBlocState {
  final User item;

  const UserLoadSuccess(this.item);

  @override
  String toString() => "${runtimeType.toString()} { item: $item }";
}

// BLOC

class UserBloc extends Bloc<UserEvent, UserBlocState> {
  final String loggedInUser;
  final UserRepository repo;
  UserBloc(this.repo, this.loggedInUser) : super(UserLoading(loggedInUser)) {
    on<UpdateUser>(
      streamToEmitterAdapterStatusAware(_mapUpdateUserEventToState),
    );
    on<LoadUser>(
      streamToEmitterAdapterStatusAware(_mapLoadUserEventToState),
    );

    add(LoadUser(loggedInUser));
  }

  Stream<UserBlocState> _mapLoadUserEventToState(LoadUser event) async* {
    try {
      final item = await repo.getItem(event.id);
      yield UserLoadSuccess(item!);
    } on SocketException catch (err) {
      throw ConnectionException(err);
    }
  }

  Stream<UserBlocState> _mapUpdateUserEventToState(UpdateUser event) async* {
    final current = state;
    if (current is UserLoadSuccess) {
      try {
        final updated = await repo.updateItem(
          event.update.username,
          repo.updateFromDiff(event.update, current.item),
        );
        yield UserLoadSuccess(updated);
      } on SocketException catch (err) {
        throw ConnectionException(err);
      }
    } else {
      throw Exception("impossible event");
    }
  }
}
