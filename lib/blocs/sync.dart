import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

import 'blocs.dart';

// EVENTS

abstract class SyncBlocEvent {
  const SyncBlocEvent();
}

/// Emits SyncFailed state if failure
class Sync extends SyncBlocEvent {}

/// Does not emit SyncFailed state if failure
class TrySync extends SyncBlocEvent with StatusAwareEvent {
  TrySync({
    OperationSuccessNotifier? onSuccess,
    OperationExceptionNotifier? onError,
  }) {
    this.onSuccess = onSuccess;
    this.onError = onError;
  }
}

class LoadSyncState extends SyncBlocEvent {}

// STATE
abstract class SyncBlocState {
  const SyncBlocState();
}

class Syncing extends SyncBlocState {}

class DeSynced extends SyncBlocState {}

class ReportedDesync extends DeSynced {}

class SyncFailed extends DeSynced {
  final SyncException exception;

  SyncFailed(this.exception);
  @override
  String toString() => "${runtimeType.toString()} { exception: $exception, }";
}

class Synced extends SyncBlocState {}

// BLOC

class SyncBloc extends Bloc<SyncBlocEvent, SyncBlocState> {
  final CacheSynchronizer refresher;
  final AuthBloc authBloc;
  final PreferencesBloc prefsBloc;

  SyncBloc(
    this.refresher,
    this.authBloc,
    this.prefsBloc,
  ) : super(Synced()) {
    on<Sync>(streamToEmitterAdapter(_handleSync));
    on<TrySync>(streamToEmitterAdapterStatusAware(_handleTrySync));
    on<LoadSyncState>(streamToEmitterAdapter(_handleLoadSyncState));
  }

  Stream<SyncBlocState> _handleLoadSyncState(LoadSyncState event) async* {
    final prefs = prefsBloc.preferencesLoadSuccessState();
    if (prefs.preferences.syncPending != null &&
        prefs.preferences.syncPending!) {
      yield ReportedDesync();
    } else {
      yield Synced();
    }
  }

  Stream<SyncBlocState> _handleSync(Sync event) async* {
    final prefs = prefsBloc.preferencesLoadSuccessState();
    yield Syncing();
    try {
      final auth = authBloc.authSuccesState();
      await refresher.syncPendingChanges(auth.username, auth.authToken);
      await refresher.refreshCache(auth.username, auth.authToken);
      yield Synced();
      prefsBloc.add(
        UpdatePreferences(
            Preferences.from(prefs.preferences, syncPending: false)),
      );
    } catch (err) {
      prefsBloc.add(
        UpdatePreferences(
            Preferences.from(prefs.preferences, syncPending: true)),
      );

      if (err is SocketException) {
        yield SyncFailed(SyncException(ConnectionException(err)));
      } else if (err is UnauthenticatedException) {
        yield SyncFailed(SyncException(err));
      } else {
        rethrow;
      }
    }
  }

  Stream<SyncBlocState> _handleTrySync(TrySync event) async* {
    final prefs = prefsBloc.preferencesLoadSuccessState();
    final current = state;
    // yield Syncing();

    final auth = authBloc.state;
    if (auth is! AuthSuccess) {
      yield current;
      return;
    }

    try {
      await refresher.syncPendingChanges(auth.username, auth.authToken);
      await refresher.refreshCache(auth.username, auth.authToken);
      yield Synced();
      prefsBloc.add(
        UpdatePreferences(
            Preferences.from(prefs.preferences, syncPending: false)),
      );
    } catch (err) {
      prefsBloc.add(
        UpdatePreferences(
            Preferences.from(prefs.preferences, syncPending: true)),
      );

      if (err is SocketException) {
        yield SyncFailed(SyncException(ConnectionException(err)));
        throw ConnectionException(err);
      } else if (err is UnauthenticatedException) {
        yield SyncFailed(SyncException(err));
        throw SyncException(err);
      } else {
        rethrow;
      }
    }
  }
}
