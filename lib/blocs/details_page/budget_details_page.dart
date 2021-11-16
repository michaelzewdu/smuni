import 'package:smuni/blocs/auth.dart';
import 'package:smuni/blocs/sync.dart';
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

class BudgetDetailsPageBloc extends DetailsPageBloc<String, Budget,
    CreateBudgetInput, UpdateBudgetInput> {
  final SyncBloc syncBloc;
  final ExpenseRepository expenseRepo;
  final OfflineExpenseRepository offlineExpenseRepo;

  BudgetDetailsPageBloc(
    ApiRepository<String, Budget, CreateBudgetInput, UpdateBudgetInput> repo,
    OfflineRepository<String, Budget, CreateBudgetInput, UpdateBudgetInput>
        offlineRepo,
    AuthBloc authBloc,
    this.expenseRepo,
    this.offlineExpenseRepo,
    this.syncBloc,
    String id,
  ) : super(repo, offlineRepo, authBloc, id) {
    on<ArchiveBudget>(
      streamToEmitterAdapterStatusAware(_handleArchiveBudget),
    );
    on<UnarchiveBudget>(
      streamToEmitterAdapterStatusAware(_handleUnarchiveBudget),
    );
  }

  // FIXME: OUR ABSTRACTIONS ARE BREAKING DOWN!
  @override
  Stream<DetailsPageState<String, Budget>> handleDeleteItem(
    DeleteItem<String, Budget> event,
  ) async* {
    final current = state;

    var totalWait = Duration();
    while (current is LoadingItem) {
      if (totalWait > Duration(seconds: 3)) throw TimeoutException();
      await Future.delayed(const Duration(milliseconds: 500));
      totalWait += const Duration(milliseconds: 500);
    }

    if (current is BudgetLoadSuccess) {
      try {
        final auth = authBloc.authSuccesState();
        await repo.removeItem(current.id, auth.username, auth.authToken, true);
        yield ItemNotFound(current.id);

        // refresh stuff since category deletion will acffect a host of items
        try {
          await syncBloc.refresher.refreshCache(auth.username, auth.authToken);
        } on SocketException catch (err) {
          // if sync failed, tell the sync bloc it need to sync
          syncBloc.add(Sync());
          // and report the sync error to whoever event added the event
          throw SyncException(ConnectionException(err));
        }
      } catch (err) {
        if (err is SocketException || err is UnauthenticatedException) {
          // do it offline if not connected or authenticated
          for (final expense in await expenseRepo
              .getItemsInRange(DateRange(), ofBudgets: {current.id})) {
            await offlineExpenseRepo.removeItemOffline(expense.id);
          }

          await offlineRepo.removeItemOffline(current.id);

          yield ItemNotFound(current.id);
        } else {
          rethrow;
        }
      }
    } else if (current is ItemNotFound) {
      throw Exception("impossible event");
    }
  }

  Stream<BudgetDetailsPageState> _handleArchiveBudget(
    ArchiveBudget event,
  ) async* {
    final current = state;

    var totalWait = Duration();
    while (current is LoadingItem) {
      if (totalWait > Duration(seconds: 3)) throw TimeoutException();
      await Future.delayed(const Duration(milliseconds: 500));
      totalWait += const Duration(milliseconds: 500);
    }
    if (current is BudgetLoadSuccess) {
      final update = UpdateBudgetInput(
        lastSeenVersion: current.item.version,
        archive: true,
      );
      try {
        final auth = authBloc.authSuccesState();
        final item = await repo.updateItem(
          current.id,
          update,
          auth.username,
          auth.authToken,
        );
        yield BudgetLoadSuccess(current.id, item);
      } catch (err) {
        // do it offline if not connected or authenticated
        if (err is SocketException || err is UnauthenticatedException) {
          final item = await offlineRepo.updateItemOffline(current.id, update);
          yield BudgetLoadSuccess(current.id, item);
        } else {
          rethrow;
        }
      }
    } else if (current is ItemNotFound) {
      throw Exception("impossible event");
    }
  }

  Stream<BudgetDetailsPageState> _handleUnarchiveBudget(
    UnarchiveBudget event,
  ) async* {
    final current = state;

    var totalWait = Duration();
    while (current is LoadingItem) {
      if (totalWait > Duration(seconds: 3)) throw TimeoutException();
      await Future.delayed(const Duration(milliseconds: 500));
      totalWait += const Duration(milliseconds: 500);
    }
    if (current is BudgetLoadSuccess) {
      final update = UpdateBudgetInput(
        lastSeenVersion: current.item.version,
        archive: false,
      );
      try {
        final auth = authBloc.authSuccesState();
        final item = await repo.updateItem(
          current.id,
          update,
          auth.username,
          auth.authToken,
        );
        yield BudgetLoadSuccess(current.id, item);
      } catch (err) {
        if (err is SocketException || err is UnauthenticatedException) {
          // do it offline if not connected or authenticated
          final item = await offlineRepo.updateItemOffline(current.id, update);
          yield BudgetLoadSuccess(current.id, item);
        } else {
          rethrow;
        }
      }
    } else if (current is ItemNotFound) {
      throw Exception("impossible event");
    }
  }
}
