import 'package:smuni/blocs/refresh.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

import 'details_page.dart';

// EVENTS

typedef CategoryDetailsPageEvent = DetailsPageEvent<String, Category>;
typedef LoadCategory = LoadItem<String, Category>;
typedef DeleteCategory = DeleteItem<String, Category>;

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

class CategoryDetailsPageBloc extends DetailsPageBloc<String, Category> {
  RefresherBloc refresherBloc;
  CategoryDetailsPageBloc(
    this.refresherBloc,
    CategoryRepository repo,
    String id,
  ) : super(repo, id) {
    on<ArchiveCategory>(
      streamToEmitterAdapterStatusAware(_handleArchiveCategory),
    );
    on<UnarchiveCategory>(
      streamToEmitterAdapterStatusAware(_handleUnarchiveCategory),
    );
  }

  // FIXME: our abstractions are breaking down
  @override
  Stream<DetailsPageState<String, Category>> handleDeleteItem(
    DeleteItem<String, Category> event,
  ) async* {
    try {
      final current = state;

      var totalWait = Duration();
      while (current is LoadingItem) {
        if (totalWait > Duration(seconds: 3)) throw TimeoutException();
        await Future.delayed(const Duration(milliseconds: 500));
        totalWait += const Duration(milliseconds: 500);
      }

      if (current is CategoryLoadSuccess) {
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

  Stream<CategoryDetailsPageState> _handleArchiveCategory(
    ArchiveCategory event,
  ) async* {
    try {
      final current = state;

      var totalWait = Duration();
      while (current is LoadingItem) {
        if (totalWait > Duration(seconds: 3)) throw TimeoutException();
        await Future.delayed(const Duration(milliseconds: 500));
        totalWait += const Duration(milliseconds: 500);
      }
      if (current is CategoryLoadSuccess) {
        final item = await repo.updateItem(
            current.id,
            UpdateCategoryInput(
                lastSeenVersion: current.item.version, archive: true));
        yield CategoryLoadSuccess(current.id, item);
      } else if (current is ItemNotFound) {
        throw Exception("impossible event");
      }
    } on SocketException catch (err) {
      throw ConnectionException(err);
    }
  }

  Stream<CategoryDetailsPageState> _handleUnarchiveCategory(
    UnarchiveCategory event,
  ) async* {
    try {
      final current = state;

      var totalWait = Duration();
      while (current is LoadingItem) {
        if (totalWait > Duration(seconds: 3)) throw TimeoutException();
        await Future.delayed(const Duration(milliseconds: 500));
        totalWait += const Duration(milliseconds: 500);
      }

      if (current is CategoryLoadSuccess) {
        final item = await repo.updateItem(
          current.id,
          UpdateCategoryInput(
              lastSeenVersion: current.item.version, archive: false),
        );
        yield CategoryLoadSuccess(current.id, item);
      } else if (current is ItemNotFound) {
        throw Exception("impossible event");
      }
    } on SocketException catch (err) {
      throw ConnectionException(err);
    }
  }
}
