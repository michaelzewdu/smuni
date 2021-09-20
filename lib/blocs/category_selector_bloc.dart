/*import 'dart:async';

import 'package:bloc/bloc.dart';

// EVENTS

abstract class CategorySelectorBlocEvent {
  const CategorySelectorBlocEvent();
}

class RemoveSelection extends CategorySelectorBlocEvent {
  const RemoveSelection();
}

class SelectCategory extends CategorySelectorBlocEvent {
  final String categoryId;
  final String budgetId;

  SelectCategory(this.categoryId, this.budgetId);
}

// STATE

abstract class CategorySelectorBlocState {}

class NoneSelected extends CategorySelectorBlocState {}

class CategorySelected extends CategorySelectorBlocState {
  final String id;
  final String budgetId;

  CategorySelected(this.id, this.budgetId);
}

// BLOC

class CategorySelectorBloc
    extends Bloc<CategorySelectorBlocEvent, CategorySelectorBlocState> {
  CategorySelectorBloc() : super(NoneSelected());

  CategorySelectorBloc.selected(String id, String budgetId)
      : super(CategorySelected(id, budgetId));

  @override
  Stream<CategorySelectorBlocState> mapEventToState(
    CategorySelectorBlocEvent event,
  ) async* {
    if (event is RemoveSelection) {
      if (state is CategorySelected) {
        yield NoneSelected();
        return;
      }
    } else if (event is SelectCategory) {
      yield CategorySelected(event.categoryId, event.budgetId);
      return;
    }
    throw Exception("Unhandled event");
  }
}
*/