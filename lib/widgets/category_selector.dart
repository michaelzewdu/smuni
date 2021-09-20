import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/categories.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/screens/Category/category_edit_page.dart';

class CategorySelectorState {
  final String id;
  final String budgetId;

  CategorySelectorState(this.id, this.budgetId);
}

class CategorySelector extends StatefulWidget {
  final CategorySelectorState? initialValue;
  final FormFieldSetter<CategorySelectorState>? onSaved;
  final FormFieldValidator<CategorySelectorState>? validator;
  final String? restorationId;

  const CategorySelector({
    Key? key,
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
            Text(
              "allocatedAmount: ETB ${item.allocatedAmount.amount / 100}",
            ),
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
      BlocBuilder<BudgetsBloc, BudgetsBlocState>(
          builder: (context, budgetsState) {
        if (budgetsState is BudgetsLoadSuccess) {
          // show the selection list
          final items = itemsState.items;
          final budgets = budgetsState.items;
          final bins = new HashMap<String, Budget>();
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
          }
          final keys = bins.keys;
          return bins.isNotEmpty
              ? SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: ListView.builder(
                    itemCount: keys.length,
                    itemBuilder: (context, index) {
                      final item = bins[keys.elementAt(index)]!;
                      return Column(
                        children: [
                          ListTile(
                            title: Text(item.name),
                            trailing: Text(
                              "${item.allocatedAmount.currency} ${item.allocatedAmount.amount / 100}",
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                                left: MediaQuery.of(context).size.width * 0.1),
                            child: Column(
                              children: [
                                ...item.categories.map(
                                  (e) => ListTile(
                                    title: Text(e.name),
                                    trailing: Text(
                                      "${e.allocatedAmount.currency} ${e.allocatedAmount.amount / 100}",
                                    ),
                                    onTap: () {
                                      state.didChange(
                                          CategorySelectorState(e.id, item.id));
                                      setState(() {
                                        _isSelecting = false;
                                      });
                                    },
                                  ),
                                ),
                                ListTile(
                                  title: const Text("Add new category"),
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      CategoryEditPage.routeName,
                                    );
                                  },
                                ),
                              ],
                            ),
                          )
                        ],
                      );
                    },
                  ),
                )
              : const Center(child: const Text("No categories."));
        } else if (budgetsState is BudgetsLoading) {
          return const Center(child: const Text("Loading budgets..."));
        }
        throw Exception("Unhandeled state");
      });

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
                state.errorText ?? "Category",
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
            BlocBuilder<CategoriesBloc, CategoriesBlocState>(
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
