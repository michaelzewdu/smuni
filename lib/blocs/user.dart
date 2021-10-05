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

  @override
  String toString() => "${this.runtimeType.toString()} { update: $update }";
}

// STATE

abstract class UserBlocState {
  const UserBlocState();
}

class UserLoading extends UserBlocState {}

class UserLoadSuccess extends UserBlocState {
  final User item;

  UserLoadSuccess(this.item);

  @override
  String toString() => "${this.runtimeType.toString()} { item: $item }";
}

// BLOC

class UserBloc extends Bloc<UserEvent, UserBlocState> {
  UserBloc(User user) : super(UserLoadSuccess(user));

  @override
  Stream<UserBlocState> mapEventToState(
    UserEvent event,
  ) async* {
    if (event is UpdateUser) {
      yield UserLoadSuccess(event.update);
      return;
    } else if (event is LoadUser) {}
  }
}
