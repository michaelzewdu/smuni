import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

import 'auth.dart';

// EVENTS

abstract class IncomesListBlocEvent {
  const IncomesListBlocEvent();
}

class LoadIncomesFilter {
  const LoadIncomesFilter();
}

class LoadIncomes extends IncomesListBlocEvent {
  final LoadIncomesFilter filter;
  const LoadIncomes({this.filter = const LoadIncomesFilter()});
  @override
  String toString() => "${runtimeType.toString()} { filter: $filter, }";
}

class DeleteIncome extends IncomesListBlocEvent {
  final String id;
  DeleteIncome(this.id);

  @override
  String toString() => "${runtimeType.toString()} { id: $id,  }";
}

// STATE

abstract class IncomeListPageBlocState {
  const IncomeListPageBlocState();
}

class IncomesLoading extends IncomeListPageBlocState {
  final LoadIncomesFilter filterUsed;
  IncomesLoading({required this.filterUsed}) : super();

  @override
  String toString() => "${runtimeType.toString()} {  filterUsed: $filterUsed }";
}

class IncomesLoadSuccess extends IncomeListPageBlocState {
  final LoadIncomesFilter filterUsed;
  final Map<String, Income> items;

  IncomesLoadSuccess(this.items, {required this.filterUsed}) : super();

  @override
  String toString() =>
      "${runtimeType.toString()} { items: $items, filterUsed: $filterUsed }";
}

// BLOC

class IncomeListPageBloc
    extends Bloc<IncomesListBlocEvent, IncomeListPageBlocState> {
  final IncomeRepository repo;
  final OfflineIncomeRepository offlineRepo;
  final AuthBloc authBloc;
  IncomeListPageBloc(
    this.repo,
    this.offlineRepo,
    this.authBloc, [
    LoadIncomesFilter initialFilter = const LoadIncomesFilter(),
  ]) : super(IncomesLoading(filterUsed: initialFilter)) {
    on<LoadIncomes>(streamToEmitterAdapter(_handleLoadBudge));
    on<DeleteIncome>(streamToEmitterAdapter(_handleDeleteIncome));

    repo.changedItems.listen(_changeItemsListener);
    offlineRepo.changedItems.listen(_changeItemsListener);
    add(LoadIncomes(filter: initialFilter));
  }

  void _changeItemsListener(Set<String> ids) {
    final current = state;
    if (current is IncomesLoading) {
      add(LoadIncomes(filter: current.filterUsed));
    } else if (current is IncomesLoadSuccess) {
      add(LoadIncomes(filter: current.filterUsed));
    } else {
      throw Exception("unhandled type");
    }
  }

  Stream<IncomeListPageBlocState> _handleLoadBudge(LoadIncomes event) async* {
    yield IncomesLoading(filterUsed: event.filter);
    final items = await repo.getItems();
    yield IncomesLoadSuccess(items, filterUsed: event.filter);
  }

  Stream<IncomeListPageBlocState> _handleDeleteIncome(
    DeleteIncome event,
  ) async* {
    final current = state;
    if (current is IncomesLoadSuccess) {
      try {
        final auth = authBloc.authSuccesState();
        await repo.removeItem(event.id, auth.username, auth.authToken);
      } catch (err) {
        if (err is SocketException || err is UnauthenticatedException) {
          // do it offline if not connected or authenticated
          await offlineRepo.removeItemOffline(
            event.id,
          );
        } else {
          rethrow;
        }
      }
      current.items.remove(event.id);
      yield IncomesLoadSuccess(current.items, filterUsed: current.filterUsed);
    } else if (current is IncomesLoading) {
      await Future.delayed(const Duration(milliseconds: 500));
      add(event);
      return;
    }
  }
}
