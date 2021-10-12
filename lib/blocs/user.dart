// FIXME:

import 'dart:async';
import 'package:bloc/bloc.dart';

import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';

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
    on<UpdateUser>(streamToEmitterAdapter(_mapUpdateUserEventToState));
    on<LoadUser>(streamToEmitterAdapter(_mapLoadUserEventToState));

    add(LoadUser(loggedInUser));
  }

  Stream<UserBlocState> _mapLoadUserEventToState(LoadUser event) async* {
    final item = await repo.getItem(event.id);
    yield UserLoadSuccess(item!);
  }

  Stream<UserBlocState> _mapUpdateUserEventToState(UpdateUser event) async* {
    final current = state;
    if (current is UserLoadSuccess) {
      await repo.updateItem(
        event.update.id,
        repo.updateFromDiff(event.update, current.item),
      );
      yield UserLoadSuccess(event.update);
    } else {
      throw Exception("impossible event");
    }
  }
}
