import 'dart:async';
import 'package:bloc/bloc.dart';

import 'package:smuni/providers/cache/cache.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/utilities.dart';

// EVENTS

abstract class PreferencesBlocEvent {
  const PreferencesBlocEvent();
}

class UpdatePreferences extends PreferencesBlocEvent with StatusAwareEvent {
  final Preferences update;

  UpdatePreferences(
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

class LoadPreferences extends PreferencesBlocEvent {}

// STATE

abstract class PreferencesBlocState {
  const PreferencesBlocState();
}

class PreferencesLoadSuccess extends PreferencesBlocState {
  final Preferences preferences;

  const PreferencesLoadSuccess(this.preferences);

  @override
  String toString() =>
      "${runtimeType.toString()} { preferences: $preferences }";
}

class PreferencesLoading extends PreferencesBlocState {}

class PreferencesLoadingFailed extends PreferencesBlocState {
  final Object? err;

  const PreferencesLoadingFailed(this.err);

  @override
  String toString() => "${runtimeType.toString()} { err: $err }";
}

// BLOC

class PreferencesBloc extends Bloc<PreferencesBlocEvent, PreferencesBlocState> {
  final PreferencesCache cache;

  PreferencesBloc(this.cache) : super(PreferencesLoading()) {
    on<LoadPreferences>(
      streamToEmitterAdapter(_handleLoadPreferences),
    );
    on<UpdatePreferences>(
      streamToEmitterAdapterStatusAware(_handleUpdatePreferences),
    );
  }
  PreferencesLoadSuccess preferencesLoadSuccessState() {
    final current = state;
    if (current is! PreferencesLoadSuccess) {
      throw Exception("prferences not loaded");
    }
    return current;
  }

  Stream<PreferencesBlocState> _handleUpdatePreferences(
    UpdatePreferences event,
  ) async* {
    final current = state;
    if (current is PreferencesLoadSuccess) {
      if (current.preferences.mainBudget != event.update.mainBudget) {
        final update = event.update.mainBudget;
        if (update != null) {
          await cache.setMainBudget(update);
        } else {
          await cache.clearMainBudget();
        }
      }
      if (current.preferences.syncPending != event.update.syncPending) {
        final update = event.update.syncPending;
        if (update != null) {
          await cache.setSyncPending(update);
        } else {
          await cache.clearSyncPending();
        }
      }
      final prefs = await cache.getPreferences();
      yield PreferencesLoadSuccess(prefs);
    } else {
      throw Exception("unexpected event");
    }
  }

  Stream<PreferencesBlocState> _handleLoadPreferences(
    LoadPreferences event,
  ) async* {
    try {
      final prefs = await cache.getPreferences();
      yield PreferencesLoadSuccess(prefs);
    } catch (err) {
      yield PreferencesLoadingFailed(err);
    }
  }
}
