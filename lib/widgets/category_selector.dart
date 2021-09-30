import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/blocs.dart';

import 'category_list_view.dart';

class CategorySelectorState {
  final String id;

  CategorySelectorState(
    this.id,
  );
}

class CategorySelector extends StatefulWidget {
  final String? caption;
  final CategorySelectorState? initialValue;
  final FormFieldSetter<CategorySelectorState>? onSaved;
  final FormFieldValidator<CategorySelectorState>? validator;
  final String? restorationId;

  const CategorySelector({
    Key? key,
    this.caption,
    this.initialValue,
    this.onSaved,
    this.validator,
    // AutovalidateMode? autovalidateMode,
    // bool? enabled,
    this.restorationId,
  }) : super(key: key);

  @override
  _CategorySelectorState createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  bool _isSelecting = false;

  Widget _viewing(
    FormFieldState<CategorySelectorState> state,
    CategoriesLoadSuccess itemsState,
  ) {
    final value = state.value;
    if (value != null) {
      final item = itemsState.items[value.id];
      if (item != null) {
        return Column(
          children: [
            Text("Name: ${item.name}"),
            Text("id: ${item.id}"),
            Text("createdAt: ${item.createdAt}"),
            Text("updatedAt: ${item.updatedAt}"),
            Text("parentId: ${item.parentId}"),
          ],
        );
      } else {
        return Center(child: const Text("Error: selected item not found."));
      }
    } else {
      return const Center(child: const Text("No category selected."));
    }
  }

  Widget _selecting(
    FormFieldState<CategorySelectorState> state,
    CategoriesLoadSuccess itemsState,
  ) =>
      Expanded(
        child: CategoryListView(
            state: itemsState,
            onSelect: (id) {
              state.didChange(CategorySelectorState(id));
              setState(() {
                _isSelecting = false;
              });
            }),
      );

  @override
  Widget build(BuildContext context) => FormField<CategorySelectorState>(
        initialValue: widget.initialValue,
        validator: widget.validator,
        onSaved: widget.onSaved,
        builder: (state) => Column(
          children: [
            // the top bar
            Row(children: [
              Expanded(
                  child: Text(
                state.errorText ?? widget.caption ?? "Category",
                style: TextStyle(
                    color: state.errorText != null ? Colors.red : null),
              )),
              TextButton(
                child:
                    _isSelecting ? const Text("Cancel") : const Text("Select"),
                onPressed: () {
                  setState(() {
                    _isSelecting = !_isSelecting;
                  });
                },
              )
            ]),
            BlocBuilder<CategoryListPageBloc, CategoryListPageBlocState>(
                builder: (context, itemsState) {
              if (itemsState is CategoriesLoadSuccess) {
                if (_isSelecting) {
                  return _selecting(state, itemsState);
                } else {
                  return _viewing(state, itemsState);
                }
              } else if (itemsState is CategoriesLoading) {
                return const Center(
                  child: const Text("Loading categories..."),
                );
              }
              throw Exception("Unhandeled state");
            })
          ],
        ),
      );
}
