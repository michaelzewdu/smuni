// FIXME:

import 'dart:async';
import 'package:bloc/bloc.dart';

import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';

// EVENTS

abstract class UserEvent {
  const UserEvent();
}

class LoadUser extends UserEvent {
  final String id;
  const LoadUser(this.id);

  @override
  String toString() => "${runtimeType.toString()} { id: $id }";
}

class UpdateUser extends UserEvent {
  final User update;
  UpdateUser(this.update);

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
    add(LoadUser(loggedInUser));
  }

  @override
  Stream<UserBlocState> mapEventToState(
    UserEvent event,
  ) async* {
    if (event is UpdateUser) {
      await repo.setItem(event.update.id, event.update);
      yield UserLoadSuccess(event.update);
      return;
    } else if (event is LoadUser) {
      final item = await repo.getItem(event.id);
      yield UserLoadSuccess(item!);
      return;
    }
    throw Exception("Unhandled event");
  }
}
