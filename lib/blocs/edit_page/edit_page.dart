export 'budget_edit_page.dart';
export 'category_edit_page.dart';
export 'expense_edit_page.dart';
export 'income_edit_page.dart';

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:smuni/blocs/auth.dart';

import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

// EVENTS

abstract class EditPageBlocEvent<Identifier, Item, CreateInput, UpdateInput> {
  const EditPageBlocEvent();
}

class UpdateItem<Identifier, Item, CreateInput, UpdateInput>
    extends EditPageBlocEvent<Identifier, Item, CreateInput, UpdateInput> {
  final Identifier id;
  final UpdateInput input;
  const UpdateItem(
    this.id,
    this.input,
  );
}

class CreateItem<Identifier, Item, CreateInput, UpdateInput>
    extends EditPageBlocEvent<Identifier, Item, CreateInput, UpdateInput> {
  final CreateInput input;
  const CreateItem(
    this.input,
  );
}

// STATE

class EditPageBlocState<Identifier, Item, CreateInput, UpdateInput> {
  const EditPageBlocState();
}

class InitialState<Identifier, Item, CreateInput, UpdateInput>
    extends EditPageBlocState<Identifier, Item, CreateInput, UpdateInput> {}

class EditFailed<Identifier, Item, CreateInput, UpdateInput>
    extends EditPageBlocState<Identifier, Item, CreateInput, UpdateInput> {
  final OperationException error;
  const EditFailed(this.error);

  @override
  String toString() => "${runtimeType.toString()} { error: $error, }";
}

class EditSuccess<Identifier, Item, CreateInput, UpdateInput>
    extends EditPageBlocState<Identifier, Item, CreateInput, UpdateInput> {
  final Identifier? id;
  final Item item;

  EditSuccess({
    this.id,
    required this.item,
  });

  @override
  String toString() =>
      "${runtimeType.toString()} { id: $item, unmodified: $item, }";
}

// BLOC

class EditPageBloc<Identifier, Item, CreateInput, UpdateInput> extends Bloc<
    EditPageBlocEvent<Identifier, Item, CreateInput, UpdateInput>,
    EditPageBlocState<Identifier, Item, CreateInput, UpdateInput>> {
  final ApiRepository<Identifier, Item, CreateInput, UpdateInput> repo;
  final OfflineRepository<Identifier, Item, dynamic, dynamic> offlineRepo;
  final AuthBloc authBloc;

  EditPageBloc(
    this.repo,
    this.offlineRepo,
    this.authBloc,
  ) : super(InitialState()) {
    on<CreateItem<Identifier, Item, CreateInput, UpdateInput>>(
      streamToEmitterAdapter(_handleCreateItem),
    );
    on<UpdateItem<Identifier, Item, CreateInput, UpdateInput>>(
      streamToEmitterAdapter(_handleUpdateItem),
    );
  }

  Stream<EditPageBlocState<Identifier, Item, CreateInput, UpdateInput>>
      _handleCreateItem(
    CreateItem event,
  ) async* {
    try {
      final auth = authBloc.authSuccesState();
      final result = await repo.createItem(
        event.input,
        auth.username,
        auth.authToken,
      );
      yield EditSuccess(item: result);
    } catch (err) {
      if (err is SocketException || err is UnauthenticatedException) {
        // do it offline if not connected or authenticated
        final result = await offlineRepo.createItemOffline(event.input);
        yield EditSuccess(item: result);
      } else {
        rethrow;
      }
    }
  }

  Stream<EditPageBlocState<Identifier, Item, CreateInput, UpdateInput>>
      _handleUpdateItem(
    UpdateItem event,
  ) async* {
    try {
      final auth = authBloc.authSuccesState();
      final result = await repo.updateItem(
        event.id,
        event.input,
        auth.username,
        auth.authToken,
      );
      yield EditSuccess(id: event.id, item: result);
    } catch (err) {
      if (err is SocketException || err is UnauthenticatedException) {
        // do it offline if not connected or authenticated
        final result =
            await offlineRepo.updateItemOffline(event.id, event.input);
        yield EditSuccess(id: event.id, item: result);
      } else {
        rethrow;
      }
    }
  }
}
