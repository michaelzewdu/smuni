import 'dart:async';
import 'package:bloc/bloc.dart';

import 'package:smuni/models/models.dart';

// EVENTS

abstract class UserEvent {
  const UserEvent();
}

class LoadUser extends UserEvent {
  const LoadUser();
}

class UpdateUser extends UserEvent {
  final User update;
  UpdateUser(this.update);
}

// STATE

abstract class UserState {
  const UserState();
}

class UsersLoading extends UserState {}

class UsersLoadSuccess extends UserState {
  final User user;

  UsersLoadSuccess(this.user);
}

// BLOC

class UsersBloc extends Bloc<UserEvent, UserState> {
  UsersBloc(User user) : super(UsersLoadSuccess(user));

  @override
  Stream<UserState> mapEventToState(
    UserEvent event,
  ) async* {
    if (event is UpdateUser) {
      yield UsersLoadSuccess(event.update);
    } else if (event is LoadUser) {}
  }
}
