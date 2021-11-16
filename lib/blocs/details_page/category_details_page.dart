import 'package:smuni/blocs/auth.dart';
import 'package:smuni/blocs/preferences.dart';
import 'package:smuni/blocs/sync.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

import 'details_page.dart';

// EVENTS

typedef CategoryDetailsPageEvent = DetailsPageEvent<String, Category>;
typedef LoadCategory = LoadItem<String, Category>;
typedef DeleteCategory = DeleteItem<String, Category>;

class MiscCategoryArchivalForbidden extends OperationException {}

class ArchiveCategory extends CategoryDetailsPageEvent with StatusAwareEvent {
  ArchiveCategory({
    OperationSuccessNotifier? onSuccess,
    OperationExceptionNotifier? onError,
  }) {
    this.onSuccess = onSuccess;
    this.onError = onError;
  }
}

class UnarchiveCategory extends CategoryDetailsPageEvent with StatusAwareEvent {
  UnarchiveCategory({
    OperationSuccessNotifier? onSuccess,
    OperationExceptionNotifier? onError,
  }) {
    this.onSuccess = onSuccess;
    this.onError = onError;
  }
}

// STATE

typedef CategoryDetailsPageState = DetailsPageState<String, Category>;
typedef CategoryLoadSuccess = LoadSuccess<String, Category>;
typedef CategoryNotFound = ItemNotFound<String, Category>;
typedef LoadingCategory = LoadingItem<String, Category>;
// BLOC

class CategoryDetailsPageBloc extends DetailsPageBloc<String, Category,
    CreateCategoryInput, UpdateCategoryInput> {
  final SyncBloc syncBloc;
  final PreferencesBloc prefsBloc;
  final ExpenseRepository expenseRepo;
  final BudgetRepository budgetRepo;
  final OfflineBudgetRepository offlineBudgetRepo;
  final OfflineExpenseRepository offlineExpenseRepo;

  CategoryDetailsPageBloc(
    CategoryRepository repo,
    OfflineRepository<String, Category, CreateCategoryInput,
            UpdateCategoryInput>
        offlineRepo,
    AuthBloc authBloc,
    this.budgetRepo,
    this.offlineBudgetRepo,
    this.expenseRepo,
    this.offlineExpenseRepo,
    this.syncBloc,
    this.prefsBloc,
    String id,
  ) : super(repo, offlineRepo, authBloc, id) {
    on<ArchiveCategory>(
      streamToEmitterAdapterStatusAware(_handleArchiveCategory),
    );
    on<UnarchiveCategory>(
      streamToEmitterAdapterStatusAware(_handleUnarchiveCategory),
    );
  }

  // FIXME: OUR ABSTRACTIONS ARE BREAKING DOWN!
  @override
  Stream<DetailsPageState<String, Category>> handleDeleteItem(
    DeleteItem<String, Category> event,
  ) async* {
    final current = state;

    var totalWait = Duration();
    while (current is LoadingItem) {
      if (totalWait > Duration(seconds: 3)) throw TimeoutException();
      await Future.delayed(const Duration(milliseconds: 500));
      totalWait += const Duration(milliseconds: 500);
    }

    if (current is CategoryLoadSuccess) {
      final prefs = prefsBloc.preferencesLoadSuccessState();
      if (prefs.preferences.miscCategory == current.id) {
        throw MiscCategoryArchivalForbidden();
      }
      try {
        final auth = authBloc.authSuccesState();
        await repo.removeItem(current.id, auth.username, auth.authToken, true);
        yield ItemNotFound(current.id);

        // refresh stuff since category deletion will acffect a host of items
        try {
          await syncBloc.refresher.refreshCache(auth.username, auth.authToken);
        } on SocketException catch (err) {
          // if refresh failed, tell the sync bloc it need to refresh
          syncBloc.add(Sync());
          // and report the sync error to whoever event added the event
          throw SyncException(ConnectionException(err));
        }
      } catch (err) {
        if (err is SocketException || err is UnauthenticatedException) {
          // do it offline if not connected or authenticated

          // assume prefernces are loaded
          final prefs = prefsBloc.preferencesLoadSuccessState();
          final miscCategoryId = prefs.preferences.miscCategory;

          for (final expense in await expenseRepo
              .getItemsInRange(DateRange(), ofCategories: {current.id})) {
            await offlineExpenseRepo.updateItemOffline(
              expense.id,
              UpdateExpenseInput(
                lastSeenVersion: expense.version,
                budgetAndCategoryId: Pair(
                  expense.budgetId,
                  miscCategoryId,
                ),
              ),
            );
          }
          for (final budget
              in (await offlineBudgetRepo.getItemsOffline()).values) {
            if (budget.categoryAllocations.containsKey(current.id)) {
              final categoryAllocations = {...budget.categoryAllocations};
              categoryAllocations[miscCategoryId] =
                  (categoryAllocations[miscCategoryId] ?? 0) +
                      categoryAllocations[current.id]!;
              categoryAllocations.remove(current.id);
              await offlineBudgetRepo.updateItemOffline(
                  budget.id,
                  UpdateBudgetInput(
                    lastSeenVersion: budget.version,
                    categoryAllocations: categoryAllocations,
                  ));
            }
          }

          for (final category in (await offlineRepo.getItemsOffline()).values) {
            if (category.parentId == current.id) {
              await offlineRepo.updateItemOffline(
                category.id,
                UpdateCategoryInput(
                  lastSeenVersion: category.version,
                  parentId: current.item.parentId ?? "",
                ),
              );
            }
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

  Stream<CategoryDetailsPageState> _handleArchiveCategory(
    ArchiveCategory event,
  ) async* {
    final current = state;

    var totalWait = Duration();
    while (current is LoadingItem) {
      if (totalWait > Duration(seconds: 3)) throw TimeoutException();
      await Future.delayed(const Duration(milliseconds: 500));
      totalWait += const Duration(milliseconds: 500);
    }
    if (current is CategoryLoadSuccess) {
      final prefs = prefsBloc.preferencesLoadSuccessState();
      if (prefs.preferences.miscCategory == current.id) {
        throw MiscCategoryArchivalForbidden();
      }
      final update = UpdateCategoryInput(
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
        yield CategoryLoadSuccess(current.id, item);
      } catch (err) {
        // do it offline if not connected or authenticated
        if (err is SocketException || err is UnauthenticatedException) {
          final item = await offlineRepo.updateItemOffline(current.id, update);
          yield CategoryLoadSuccess(current.id, item);
        } else {
          rethrow;
        }
      }
    } else if (current is ItemNotFound) {
      throw Exception("impossible event");
    }
  }

  Stream<CategoryDetailsPageState> _handleUnarchiveCategory(
    UnarchiveCategory event,
  ) async* {
    final current = state;

    var totalWait = Duration();
    while (current is LoadingItem) {
      if (totalWait > Duration(seconds: 3)) throw TimeoutException();
      await Future.delayed(const Duration(milliseconds: 500));
      totalWait += const Duration(milliseconds: 500);
    }
    if (current is CategoryLoadSuccess) {
      final update = UpdateCategoryInput(
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
        yield CategoryLoadSuccess(current.id, item);
      } catch (err) {
        if (err is SocketException || err is UnauthenticatedException) {
          // do it offline if not connected or authenticated
          final item = await offlineRepo.updateItemOffline(current.id, update);
          yield CategoryLoadSuccess(current.id, item);
        } else {
          rethrow;
        }
      }
    } else if (current is ItemNotFound) {
      throw Exception("impossible event");
    }
  }
}
