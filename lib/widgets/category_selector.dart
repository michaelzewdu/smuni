import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/models/models.dart';
import 'package:smuni/blocs/blocs.dart';

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

  Widget _catDisplay(
    FormFieldState<CategorySelectorState> state,
    CategoriesLoadSuccess itemsState,
    String id,
  ) {
    final item = itemsState.items[id];
    final itemNode = itemsState.ancestryGraph[id];
    if (item == null) return Text("Error: Category under id $id not found");
    if (itemNode == null)
      return Text("Error: Category under id $id not found in ancestryGraph");

    Widget listTile(Category item) => ListTile(
          title: Text(item.name),
          subtitle: Text(item.tags.map((e) => "#$e").toList().join(" ")),
          onTap: () {
            state.didChange(CategorySelectorState(id));
            setState(() {
              _isSelecting = false;
            });
          },
        );
    return itemNode.children.isEmpty
        ? listTile(item)
        : Column(
            children: [
              listTile(item),
              if (itemNode.children.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(
                      left: MediaQuery.of(context).size.width * 0.1),
                  child: Column(
                    children: [
                      ...itemNode.children
                          .map((e) => _catDisplay(state, itemsState, e)),
                      /*ListTile(
                                  title: const Text("Add new category"),
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      CategoryEditPage.routeName,
                                    );
                                  },
                                ),*/
                    ],
                  ),
                )
            ],
          );
  }

  Widget _selecting(
    FormFieldState<CategorySelectorState> state,
    CategoriesLoadSuccess itemsState,
  ) {
    // show the selection list
    final topNodes =
        itemsState.ancestryGraph.values.where((e) => e.parent == null).toList();
    /*final bins = new HashMap<String, List<String>>();
    for (final item in items.values) {
      final budget = budgets[item.budgetId];
      if (budget != null) {
        bins.update(
          budget.id,
          (budget) => budget..categories.add(item),
          ifAbsent: () => Budget.from(budget, categories: [item]),
        );
      } else {
        return Text("Error: Budget not found for category $item.name");
      }
    }*/
    return topNodes.isNotEmpty
        ? SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: ListView.builder(
              itemCount: topNodes.length,
              itemBuilder: (context, index) =>
                  _catDisplay(state, itemsState, topNodes[index].item),
            ),
          )
        : const Center(child: const Text("No categories."));
  }

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
