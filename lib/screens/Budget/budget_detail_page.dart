import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/screens/Expense/expense_edit_page.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni/widgets/expense_list_view.dart';

import 'budget_edit_page.dart';

class BudgetDetailsPage extends StatefulWidget {
  static const String routeName = "budgetDetails";

  static Route route(String id) => MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (context) => MultiBlocProvider(providers: [
          BlocProvider(
            create: (BuildContext context) => DetailsPageBloc<String, Budget>(
                context.read<BudgetRepository>(), id),
          ),
          BlocProvider(
            create: (BuildContext context) => ExpenseListPageBloc(
                context.read<ExpenseRepository>(),
                context.read<CategoryRepository>(),
                const DateRangeFilter(
                  "All",
                  DateRange(),
                  FilterLevel.All,
                ),
                id),
          ),
          BlocProvider(
            create: (BuildContext context) =>
                CategoryListPageBloc(context.read<CategoryRepository>()),
          ),
        ], child: BudgetDetailsPage()),
      );

  const BudgetDetailsPage({Key? key}) : super(key: key);

  @override
  State<BudgetDetailsPage> createState() => _BudgetDetailsPageState();
}

class _BudgetDetailsPageState extends State<BudgetDetailsPage> {
  int? _totalUsed;
  Map<String, int>? _perCategoryUsed;
  String? _selectedCategory;

  Widget _catTree(
    BuildContext context,
    LoadSuccess<String, Budget> state,
    CategoriesLoadSuccess catListState,
    Set<String> nodesToShow,
    Map<String, int> perCategoryUsed,
    String id,
  ) {
    final item = catListState.items[id];
    final itemNode = catListState.ancestryGraph[id];
    if (item == null) return Text("Error: Category under id $id not found");
    if (itemNode == null)
      return Text("Error: Category under id $id not found in ancestryGraph");

    final children = itemNode.children.where((e) => nodesToShow.contains(e));

    final allocatedAmount = state.item.categories[id];
    return Column(
      children: [
        allocatedAmount != null
            ? Builder(builder: (context) {
                final used = perCategoryUsed[id] ?? 0;
                return ListTile(
                  title: Text(item.name),
                  subtitle:
                      Text(item.tags.map((e) => "#$e").toList().join(" ")),
                  // dense: true,
                  trailing: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: Column(
                      children: [
                        Text("${used / 100} / ${allocatedAmount.amount / 100}"),
                        LinearProgressIndicator(
                          value: used / allocatedAmount.amount,
                        )
                      ],
                    ),
                  ),
                  /* onTap: () => Navigator.pushNamed(
                    context,
                    CategoryDetailsPage.routeName,
                    arguments: item.id,
                  ), */
                  onTap: () => setState(() {
                    if (_selectedCategory == id) {
                      _selectedCategory = null;
                    } else {
                      _selectedCategory = id;
                    }
                  }),
                );
              })
            : ListTile(
                title: Text(item.name),
                dense: true,
              ),
        if (children.isNotEmpty || _selectedCategory == id)
          Padding(
            padding:
                EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.05),
            child: Column(
              children: [
                if (_selectedCategory == id)
                  Container(
                    decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius:
                            BorderRadius.vertical(bottom: Radius.circular(15))),
                    child: Column(children: [
                      ListTile(
                          leading: Icon(Icons.add),
                          dense: true,
                          title: const Text("Add new expense"),
                          onTap: () => Navigator.pushNamed(
                                context,
                                ExpenseEditPage.routeName,
                              )),
                      ListTile(
                        leading: Icon(Icons.list),
                        dense: true,
                        title: const Text("Show Expenses"),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => BlocProvider(
                                create: (context) => ExpenseListPageBloc(
                                      context.read<ExpenseRepository>(),
                                      context.read<CategoryRepository>(),
                                      const DateRangeFilter(
                                        "All",
                                        DateRange(),
                                        FilterLevel.All,
                                      ),
                                      state.id,
                                      id,
                                    ),
                                child: BlocBuilder<ExpenseListPageBloc,
                                        ExpenseListPageBlocState>(
                                    builder: (context, expensesState) {
                                  if (expensesState is ExpensesLoadSuccess) {
                                    return Column(
                                      children: [
                                        Center(
                                            child: ElevatedButton(
                                          child: const Text("Add Expense"),
                                          onPressed: () => Navigator.pushNamed(
                                            context,
                                            ExpenseEditPage.routeName,
                                          ),
                                        )),
                                        ExpenseListView(
                                            dense: true,
                                            items: expensesState.items,
                                            allDateRanges: expensesState
                                                .dateRangeFilters.values,
                                            displayedRange: expensesState.range,
                                            loadRange: (range) => context
                                                .read<ExpenseListPageBloc>()
                                                .add(LoadExpenses(range))),
                                      ],
                                    );
                                  }
                                  return Center(
                                      child:
                                          CircularProgressIndicator.adaptive());
                                })),
                          );
                        },
                      ),
                    ]),
                  ),
                ...itemNode.children.map(
                  (e) => _catTree(
                    context,
                    state,
                    catListState,
                    nodesToShow,
                    perCategoryUsed,
                    e,
                  ),
                ),
              ],
            ),
          )
      ],
    );
  }

  Widget _showDetails(
    BuildContext context,
    LoadSuccess<String, Budget> state,
  ) {
    final currency = state.item.allocatedAmount.currency;
    final totalAllocated = state.item.allocatedAmount.amount;

    return BlocListener<ExpenseListPageBloc, ExpenseListPageBlocState>(
      listener: (context, expensesState) {
        if (expensesState is ExpensesLoadSuccess) {
          var totalUsed = 0;
          Map<String, int> perCategoryUsed = HashMap();
          for (final expense in expensesState.items.values) {
            final expenseAmount = expense.amount.amount;
            totalUsed += expenseAmount;
            perCategoryUsed.update(
              expense.categoryId,
              (value) => value + expenseAmount,
              ifAbsent: () => expenseAmount,
            );
          }
          setState(() {
            _totalUsed = totalUsed;
            _perCategoryUsed = perCategoryUsed;
          });
        } else {
          setState(() {
            _totalUsed = null;
            _perCategoryUsed = null;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(state.item.name),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                BudgetEditPage.routeName,
                arguments: state.item.id,
              ),
              child: const Text("Edit"),
            ),
            ElevatedButton(
              onPressed: () => showDialog<bool?>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm deletion'),
                  content: Text(
                      'Are you sure you want to delete entry ${state.item.name}?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      child: const Text('Confirm'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ).then(
                (confirm) {
                  if (confirm != null && confirm) {
                    context
                        .read<DetailsPageBloc<String, Budget>>()
                        .add(DeleteItem());
                    Navigator.pop(context);
                  }
                },
              ),
              child: const Text("Delete"),
            )
          ],
        ),
        body: Column(
          children: <Widget>[
            Text(state.item.name),
            Text("frequency: ${state.item.frequency}"),
            Text("startTime: ${state.item.startTime}"),
            Text("endTime: ${state.item.endTime}"),
            Text("id: ${state.item.id}"),
            Text("createdAt: ${state.item.createdAt}"),
            Text("updatedAt: ${state.item.updatedAt}"),
            _totalUsed != null
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(15)),
                      child: Column(
                        children: [
                          Text(
                            "Allocated:  $currency ${totalAllocated / 100}",
                          ),
                          Text(
                            "Used:  $currency ${_totalUsed! / 100}",
                          ),
                          Text(
                            "Remaining:  $currency ${(totalAllocated - _totalUsed!) / 100}",
                          ),
                          if (totalAllocated > 0)
                            LinearProgressIndicator(
                              value: _totalUsed! / totalAllocated,
                            ),
                          ListTile(
                            leading: Icon(Icons.list),
                            dense: true,
                            title: const Text("Show Expenses"),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) => BlocProvider(
                                    create: (context) => ExpenseListPageBloc(
                                          context.read<ExpenseRepository>(),
                                          context.read<CategoryRepository>(),
                                          const DateRangeFilter(
                                            "All",
                                            DateRange(),
                                            FilterLevel.All,
                                          ),
                                          state.id,
                                        ),
                                    child: BlocBuilder<ExpenseListPageBloc,
                                            ExpenseListPageBlocState>(
                                        builder: (context, expensesState) {
                                      if (expensesState
                                          is ExpensesLoadSuccess) {
                                        return Column(
                                          children: [
                                            Center(
                                                child: ElevatedButton(
                                              child: const Text("Add Expense"),
                                              onPressed: () =>
                                                  Navigator.pushNamed(
                                                context,
                                                ExpenseEditPage.routeName,
                                              ),
                                            )),
                                            ExpenseListView(
                                                dense: true,
                                                items: expensesState.items,
                                                allDateRanges: expensesState
                                                    .dateRangeFilters.values,
                                                displayedRange:
                                                    expensesState.range,
                                                loadRange: (range) => context
                                                    .read<ExpenseListPageBloc>()
                                                    .add(LoadExpenses(range))),
                                          ],
                                        );
                                      }
                                      return Center(
                                          child: CircularProgressIndicator
                                              .adaptive());
                                    })),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                : const Center(child: CircularProgressIndicator.adaptive()),
            const Text("Categories"),
            Expanded(
              child: _perCategoryUsed != null
                  ? BlocBuilder<CategoryListPageBloc,
                      CategoryListPageBlocState>(
                      builder: (context, catListState) {
                        if (catListState is CategoriesLoadSuccess) {
                          Set<String> nodes = new LinkedHashSet();
                          Set<String> rootNodes = new LinkedHashSet();
                          for (final id in state.item.categories.keys) {
                            final node = catListState.ancestryGraph[id];
                            if (node == null)
                              throw Exception("unexpected null");
                            var curNode = node;
                            while (true) {
                              nodes.add(curNode.item);
                              if (curNode.parent != null) {
                                curNode = curNode.parent!;
                              } else {
                                rootNodes.add(curNode.item);
                                break;
                              }
                            }
                          }
                          return rootNodes.isNotEmpty
                              ? ListView.builder(
                                  itemCount: rootNodes.length,
                                  itemBuilder: (context, index) {
                                    final item = rootNodes.elementAt(index);
                                    return _catTree(
                                        context,
                                        state,
                                        catListState,
                                        nodes,
                                        _perCategoryUsed!,
                                        item);
                                  },
                                )
                              : catListState.items.isEmpty
                                  ? Center(child: const Text("No categories."))
                                  : throw Exception("parents are missing");
                        }
                        return const Center(
                            child: CircularProgressIndicator.adaptive());
                      },
                    )
                  : const Center(child: CircularProgressIndicator.adaptive()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DetailsPageBloc<String, Budget>, DetailsPageState>(
        builder: (context, state) {
          if (state is LoadSuccess<String, Budget>) {
            return _showDetails(context, state);
          } else if (state is LoadingItem) {
            return Scaffold(
              appBar: AppBar(
                title: const Text("Loading budget..."),
              ),
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (state is ItemNotFound) {
            return Scaffold(
              appBar: AppBar(
                title: const Text("Item not found"),
              ),
              body: Center(
                child: Text(
                  "Error: unable to find item at id: ${state.id}.",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          throw Exception("Unhandled state");
        },
      );
}
