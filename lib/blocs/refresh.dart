import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

// EVENTS

abstract class RefresherBlocEvent {
  const RefresherBlocEvent();
}

class Refresh extends RefresherBlocEvent {}
// STATE

abstract class RefresherBlocState {
  const RefresherBlocState();
}

class Refreshing extends RefresherBlocState {}

class RefreshFailed extends RefresherBlocState {
  final RefreshException exception;

  RefreshFailed(this.exception);
  @override
  String toString() => "${runtimeType.toString()} { exception: $exception, }";
}

class Refreshed extends RefresherBlocState {}

// BLOC

class RefresherBloc extends Bloc<RefresherBlocEvent, RefresherBlocState> {
  CacheRefresher refresher;
  RefresherBloc(this.refresher) : super(Refreshed()) {
    on<Refresh>(streamToEmitterAdapter(_handleRefresh));
  }

  Stream<RefresherBlocState> _handleRefresh(Refresh event) async* {
    yield Refreshing();
    try {
      await refresher.refreshCache();
      yield Refreshed();
    } on SocketException catch (err) {
      yield RefreshFailed(RefreshException(ConnectionException(err)));
    }
  }
}
