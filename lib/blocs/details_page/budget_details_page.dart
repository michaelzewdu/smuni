import 'package:smuni/blocs/refresh.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

import 'details_page.dart';

// EVENTS

typedef BudgetDetailsPageEvent = DetailsPageEvent<String, Budget>;
typedef LoadBudget = LoadItem<String, Budget>;
typedef DeleteBudget = DeleteItem<String, Budget>;

class ArchiveBudget extends BudgetDetailsPageEvent with StatusAwareEvent {
  ArchiveBudget({
    OperationSuccessNotifier? onSuccess,
    OperationExceptionNotifier? onError,
  }) {
    this.onSuccess = onSuccess;
    this.onError = onError;
  }
}

class UnarchiveBudget extends BudgetDetailsPageEvent with StatusAwareEvent {
  UnarchiveBudget({
    OperationSuccessNotifier? onSuccess,
    OperationExceptionNotifier? onError,
  }) {
    this.onSuccess = onSuccess;
    this.onError = onError;
  }
}

// STATE

typedef BudgetDetailsPageState = DetailsPageState<String, Budget>;
typedef BudgetLoadSuccess = LoadSuccess<String, Budget>;
typedef BudgetNotFound = ItemNotFound<String, Budget>;
typedef LoadingBudget = LoadingItem<String, Budget>;
// BLOC

class BudgetDetailsPageBloc extends DetailsPageBloc<String, Budget> {
  RefresherBloc refresherBloc;
  BudgetDetailsPageBloc(
    this.refresherBloc,
    Repository<String, Budget, CreateBudgetInput, UpdateBudgetInput> repo,
    String id,
  ) : super(repo, id) {
    on<ArchiveBudget>(
      streamToEmitterAdapterStatusAware(_handleArchiveBudget),
    );
    on<UnarchiveBudget>(
      streamToEmitterAdapterStatusAware(_handleUnarchiveBudget),
    );
  }

  // FIXME: our abstractions are breaking down
  @override
  Stream<DetailsPageState<String, Budget>> handleDeleteItem(
    DeleteItem<String, Budget> event,
  ) async* {
    try {
      final current = state;

      var totalWait = Duration();
      while (current is LoadingItem) {
        if (totalWait > Duration(seconds: 3)) throw TimeoutException();
        await Future.delayed(const Duration(milliseconds: 500));
        totalWait += const Duration(milliseconds: 500);
      }

      if (current is BudgetLoadSuccess) {
        await repo.removeItem(current.id, true);
        yield ItemNotFound(current.id);
      } else if (current is ItemNotFound) {
        throw Exception("impossible event");
      }
    } on SocketException catch (err) {
      throw ConnectionException(err);
    }

    try {
      await refresherBloc.refresher.refreshCache();
    } on SocketException catch (err) {
      // if refresh failed, tell the refresher bloc it need to refresh
      refresherBloc.add(Refresh());
      // and report the refresh error to whoever event added the event
      throw RefreshException(ConnectionException(err));
    }
  }

  Stream<BudgetDetailsPageState> _handleArchiveBudget(
    ArchiveBudget event,
  ) async* {
    try {
      final current = state;

      var totalWait = Duration();
      while (current is LoadingItem) {
        if (totalWait > Duration(seconds: 3)) throw TimeoutException();
        await Future.delayed(const Duration(milliseconds: 500));
        totalWait += const Duration(milliseconds: 500);
      }
      if (current is BudgetLoadSuccess) {
        final item = await repo.updateItem(
            current.id,
            UpdateBudgetInput(
                lastSeenVersion: current.item.version, archive: true));
        yield BudgetLoadSuccess(current.id, item);
      } else if (current is ItemNotFound) {
        throw Exception("impossible event");
      }
    } on SocketException catch (err) {
      throw ConnectionException(err);
    }
  }

  Stream<BudgetDetailsPageState> _handleUnarchiveBudget(
    UnarchiveBudget event,
  ) async* {
    try {
      final current = state;

      var totalWait = Duration();
      while (current is LoadingItem) {
        if (totalWait > Duration(seconds: 3)) throw TimeoutException();
        await Future.delayed(const Duration(milliseconds: 500));
        totalWait += const Duration(milliseconds: 500);
      }

      if (current is BudgetLoadSuccess) {
        final item = await repo.updateItem(
          current.id,
          UpdateBudgetInput(
              lastSeenVersion: current.item.version, archive: false),
        );
        yield BudgetLoadSuccess(current.id, item);
      } else if (current is ItemNotFound) {
        throw Exception("impossible event");
      }
    } on SocketException catch (err) {
      throw ConnectionException(err);
    }
  }
}
