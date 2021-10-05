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
        builder: (context) => page(id),
      );

  static Widget page(
    String id, [
    List<Widget> Function(BuildContext, LoadSuccess<String, Budget>)
        actionsListBuilder = defaultActionsListBuilder,
  ]) {
    return MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (BuildContext context) => DetailsPageBloc<String, Budget>(
                context.read<BudgetRepository>(), id),
          ),
          BlocProvider(
            create: (BuildContext context) => ExpenseListPageBloc(
                context.read<ExpenseRepository>(),
                context.read<BudgetRepository>(),
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
        ],
        child: BudgetDetailsPage(
          actionsListBuilder: actionsListBuilder,
        ));
  }

  static List<Widget> defaultActionsListBuilder(
          BuildContext context, LoadSuccess<String, Budget> state) =>
      [
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(
            context,
            BudgetEditPage.routeName,
            arguments: state.item.id,
          ),
          child: const Text("Edit"),
        ),
        ElevatedButton(
          child: const Text("Delete"),
          onPressed: () => showDialog<bool?>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirm deletion'),
              content: Text(
                  'Are you sure you want to delete entry ${state.item.name}?\nTODO: decide on how deletion works'),
              actions: <Widget>[
                TextButton(
                  /* onPressed: () {
                        Navigator.pop(context, true);
                      }, */
                  onPressed: null,
                  child: const Text('TODO'),
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
                    .read<DetailsPageBloc<String, Expense>>()
                    .add(DeleteItem());
                Navigator.pop(context);
              }
            },
          ),
        )
      ];

  final List<Widget> Function(BuildContext, LoadSuccess<String, Budget>)
      actionsListBuilder;

  BudgetDetailsPage(
      {Key? key, this.actionsListBuilder = defaultActionsListBuilder})
      : super(key: key);

  @override
  State<BudgetDetailsPage> createState() => _BudgetDetailsPageState();
}

class _BudgetDetailsPageState extends State<BudgetDetailsPage> {
  int? _totalUsed;
  Map<String, int>? _perCategoryUsed;
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DetailsPageBloc<String, Budget>, DetailsPageState>(
        builder: (context, state) {
          if (state is LoadSuccess<String, Budget>) {
            return _details(context, state);
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

  Widget _details(BuildContext context, LoadSuccess<String, Budget> state) {
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
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              toolbarHeight: 60,
              title: Text(state.item.name),

              shape: RoundedRectangleBorder(
                  side: BorderSide.none,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(30))),
              expandedHeight: 250,
              pinned: true,
              //floating: true,
              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 60, 0, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(state.item.name),
                        Text("frequency: ${state.item.frequency}"),
                        Text("startTime: ${state.item.startTime}"),
                        Text("endTime: ${state.item.endTime}"),
                        Text("id: ${state.item.id}"),
                        Text("createdAt: ${state.item.createdAt}"),
                        Text("updatedAt: ${state.item.updatedAt}"),
                      ],
                    ),
                  ),
                ),
              ),
              actions: widget.actionsListBuilder(context, state),
            ),
            _totalUsed != null
                ? SliverToBoxAdapter(
                    child: Padding(
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
                              style: _totalUsed! > totalAllocated
                                  ? TextStyle(color: Colors.red)
                                  : null,
                            ),
                            Text(
                              "Remaining:  $currency ${(totalAllocated - _totalUsed!) / 100}",
                              style: _totalUsed! > totalAllocated
                                  ? TextStyle(color: Colors.red)
                                  : null,
                            ),
                            if (totalAllocated > 0)
                              LinearProgressIndicator(
                                value: _totalUsed! / totalAllocated,
                                color: _totalUsed! > totalAllocated
                                    ? Colors.red
                                    : null,
                              ),
                            ListTile(
                              leading: Icon(Icons.list),
                              title: const Text("Show Expenses"),
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) => BlocProvider(
                                      create: (context) => ExpenseListPageBloc(
                                            context.read<ExpenseRepository>(),
                                            context.read<BudgetRepository>(),
                                            context.read<CategoryRepository>(),
                                            const DateRangeFilter(
                                              "All",
                                              DateRange(),
                                              FilterLevel.All,
                                            ),
                                            state.item.id,
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
                                                child:
                                                    const Text("Add Expense"),
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
                                                      .read<
                                                          ExpenseListPageBloc>()
                                                      .add(LoadExpenses(
                                                        range,
                                                        ofBudget: state.item.id,
                                                      ))),
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
                    ),
                  )
                : SliverFillRemaining(
                    child: const Center(
                        child: CircularProgressIndicator.adaptive()),
                  ),
            _perCategoryUsed != null
                ? BlocBuilder<CategoryListPageBloc, CategoryListPageBlocState>(
                    builder: (context, catListState) {
                      if (catListState is CategoriesLoadSuccess) {
                        Set<String> nodes = new LinkedHashSet();
                        Set<String> rootNodes = new LinkedHashSet();
                        for (final id in state.item.categoryAllocation.keys) {
                          final node = catListState.ancestryGraph[id];
                          if (node == null) throw Exception("unexpected null");
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
                            ? SliverList(
                                delegate: SliverChildBuilderDelegate(
                                    (BuildContext context, int index) {
                                  final item = rootNodes.elementAt(index);
                                  return _catTree(context, state, catListState,
                                      nodes, _perCategoryUsed!, item);
                                }, childCount: rootNodes.length),
                              )
                            : catListState.items.isEmpty
                                ? SliverFillRemaining(
                                    child: Center(
                                        child: const Text("No categories.")))
                                : throw Exception("parents are missing");
                      }
                      return const SliverFillRemaining(
                          child: Center(
                              child: CircularProgressIndicator.adaptive()));
                    },
                  )
                : const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator.adaptive())),
          ],
        ),
      ),
    );
  }

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

    final allocatedAmount = state.item.categoryAllocation[id];
    return Column(
      children: [
        allocatedAmount != null
            ? Builder(builder: (context) {
                final used = perCategoryUsed[id] ?? 0;
                return ListTile(
                  title: Text(item.name),
                  subtitle:
                      Text(item.tags.map((e) => "#$e").toList().join(" ")),
                  trailing: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: Column(
                      children: [
                        Text("${used / 100} / ${allocatedAmount / 100}"),
                        LinearProgressIndicator(
                          value: used / allocatedAmount,
                          color: used > allocatedAmount ? Colors.red : null,
                        )
                      ],
                    ),
                  ),
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
                dense: true,
                title: Text(item.name),
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
                        title: const Text("Add new expense"),
                        leading: Icon(Icons.add),
                        onTap: () => Navigator.pushNamed(
                          context,
                          ExpenseEditPage.routeName,
                          arguments: ExpenseEditPageNewArgs(
                              budgetId: state.item.id, categoryId: item.id),
                        ),
                      ),
                      ListTile(
                        title: const Text("Show Expenses"),
                        leading: Icon(Icons.list),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => BlocProvider(
                                create: (context) => ExpenseListPageBloc(
                                      context.read<ExpenseRepository>(),
                                      context.read<BudgetRepository>(),
                                      context.read<CategoryRepository>(),
                                      const DateRangeFilter(
                                        "All",
                                        DateRange(),
                                        FilterLevel.All,
                                      ),
                                      state.item.id,
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
                                            arguments: ExpenseEditPageNewArgs(
                                                budgetId: state.item.id,
                                                categoryId: item.id),
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
                                                .add(LoadExpenses(range,
                                                    ofBudget: state.item.id,
                                                    ofCategory: item.id))),
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
}
