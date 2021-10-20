import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/screens/Expense/expense_edit_page.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni/widgets/expense_list_view.dart';

import '../../constants.dart';
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
  ]) =>
      MultiBlocProvider(
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
                    FilterLevel.all,
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

  static List<Widget> defaultActionsListBuilder(
    BuildContext context,
    LoadSuccess<String, Budget> state,
  ) =>
      [
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(
            context,
            BudgetEditPage.routeName,
            arguments: state.item,
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
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  /* onPressed: () {
                        Navigator.pop(context, true);
                      }, */
                  onPressed: null,
                  child: const Text('TODO'),
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
  State<BudgetDetailsPage> createState() => _BudgetDetailsPageState2();
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
                        RichText(
                            text: TextSpan(children: [
                          TextSpan(
                              text: 'Current  ',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w200)),
                          TextSpan(
                              text: 'Standings', style: TextStyle(fontSize: 23))
                        ])),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                                text: TextSpan(children: [
                              TextSpan(
                                  text: 'Used: ',
                                  style: TextStyle(fontSize: 18)),
                              _totalUsed != null
                                  ? TextSpan(
                                      text: "$currency ${_totalUsed! / 100}",
                                      style: _totalUsed! > totalAllocated
                                          ? TextStyle(
                                              color: Colors.red, fontSize: 18)
                                          : null,
                                    )
                                  : TextSpan(text: 'loading..'),
                            ])),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: RichText(
                                  text: TextSpan(children: [
                                TextSpan(
                                    text: 'Remaining: ',
                                    style: TextStyle(fontSize: 18)),
                                _totalUsed != null
                                    ? TextSpan(
                                        text:
                                            "$currency ${(totalAllocated - _totalUsed!) / 100}",
                                        style: _totalUsed! > totalAllocated
                                            ? TextStyle(
                                                color: Colors.red,
                                                //backgroundColor: Colors.white,
                                                fontSize: 18)
                                            : TextStyle(
                                                color: Colors.black,
                                                backgroundColor: Colors.white,
                                                fontSize: 20),
                                      )
                                    : TextSpan(text: 'loading..'),
                              ])),
                            ),
                            RichText(
                                text: TextSpan(children: [
                              TextSpan(text: 'Allocated: '),
                              _totalUsed != null
                                  ? TextSpan(
                                      text: "$currency ${totalAllocated / 100}",
                                    )
                                  : TextSpan(text: 'loading..'),
                            ])),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: widget.actionsListBuilder(context, state),
            ),
            /*
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
                                              FilterLevel.all,
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

             */
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 22, horizontal: 16.0),
                child: Text('${state.item.name}\'s categories',
                    style:
                        GoogleFonts.secularOne(fontSize: 23, color: semuni700)),
              ),
              /*
              child: BlocBuilder<UserBloc, UserBlocState>(
                  builder: (context, userState) {
                if (userState is UserLoadSuccess &&
                    userState.item.mainBudget != null) {
                  return Text(userState.item.mainBudget!);
                } else {
                  return Text('Budget Categories');
                }
              }),

               */
            ),
            _perCategoryUsed != null
                ? BlocBuilder<CategoryListPageBloc, CategoryListPageBlocState>(
                    builder: (context, catListState) {
                      if (catListState is CategoriesLoadSuccess) {
                        // ignore: prefer_collection_literals
                        Set<String> nodes = LinkedHashSet();
                        // ignore: prefer_collection_literals
                        Set<String> rootNodes = LinkedHashSet();
                        for (final id in state.item.categoryAllocations.keys) {
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
                            : state.item.categoryAllocations.isEmpty
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
    if (itemNode == null) {
      return Text("Error: Category under id $id not found in ancestryGraph");
    }

    final children = itemNode.children.where((e) => nodesToShow.contains(e));

    final allocatedAmount = state.item.categoryAllocations[id];
    return Column(
      children: [
        allocatedAmount != null
            ? Builder(builder: (context) {
                final used = perCategoryUsed[id] ?? 0;
                return ListTile(
                  title: Text(item.name, style: TextStyle(fontSize: 18)),
                  subtitle: item.tags.isEmpty
                      ? null
                      : Text(item.tags.map((e) => "#$e").toList().join(" ")),
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
                                        FilterLevel.all,
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

class _BudgetDetailsPageState2 extends State<BudgetDetailsPage> {
  int? _totalUsed;
  Map<String, int>? _perCategoryUsed;
  String? _selectedCategory;

  var _showAllBudgetExpenses = false;

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

  Widget _details(
    BuildContext context,
    LoadSuccess<String, Budget> state,
  ) =>
      Scaffold(
        body: _budgetDetails(context, state),
      );

  Widget _budgetDetails(
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
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            toolbarHeight: 60,
            title: Text(state.item.name),
            shape: RoundedRectangleBorder(
              side: BorderSide.none,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30)),
            ),
            expandedHeight: 250,
            pinned: true,
            //floating: true,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 60, 0, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _totalUsed != null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...<dynamic>[
                                  [
                                    'Used',
                                    "${_totalUsed! / 100}",
                                    _totalUsed! > totalAllocated
                                  ],
                                  [
                                    'Remaining',
                                    "${(totalAllocated - _totalUsed!) / 100}",
                                    _totalUsed! > totalAllocated
                                  ],
                                  ['Total', "${totalAllocated / 100}", false],
                                ].map(((e) => DefaultTextStyle(
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(e[0]),
                                          DefaultTextStyle(
                                            style: const TextStyle(
                                              fontSize: 20,
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  "$currency ",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w200),
                                                ),
                                                Text(
                                                  e[1],
                                                  style: TextStyle(
                                                    backgroundColor: e[2]
                                                        ? Colors.red[700]
                                                        : null,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))),
                              ],
                            )
                          : CircularProgressIndicator(
                              color: Colors.white,
                            ),
                      _totalUsed != null
                          ? Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                // crossAxisAlignment: CrossAxisAlignment.start?,
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: DefaultTextStyle(
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 44,
                                          ),
                                          child: totalAllocated == 0
                                              ? Text("0%")
                                              : Builder(builder: (context) {
                                                  final percentage =
                                                      ((_totalUsed! /
                                                                  totalAllocated) *
                                                              100)
                                                          .truncate();
                                                  return FittedBox(
                                                    child: Text(
                                                      "$percentage%",
                                                      style: percentage >= 100
                                                          ? TextStyle(
                                                              backgroundColor:
                                                                  Colors
                                                                      .red[700],
                                                            )
                                                          : null,
                                                    ),
                                                  );
                                                })),
                                    ),
                                  ),
                                  // span = endTime - startTime
                                  // noOfCyclesPast = (( now - startTime) / recurrenceInterval).truncate();
                                  // startOfCurrentCycle = (noOfCyclesPast * recurrenceInterval) + startTime;
                                  // endOfCurrentCycle = startOfCurrentCycle + span;
                                  if (state.item.frequency is Recurring)
                                    Builder(builder: (context) {
                                      Duration span = state.item.endTime
                                          .difference(state.item.startTime);
                                      int recurrenceIntervalSeconds =
                                          (state.item.frequency as Recurring)
                                              .recurringIntervalSecs;
                                      // print('recurrenceIntervalSeconds: $recurrenceIntervalSeconds');
                                      int untilNow = DateTime.now()
                                          .difference(state.item.startTime)
                                          .inSeconds;
                                      // print('UntilNow: $untilNow');
                                      int numberOfRecurringCyclesPassed =
                                          (untilNow / recurrenceIntervalSeconds)
                                              .ceil();
                                      // print('numberOfRecurringCyclesPasssed: $numberOfRecurringCyclesPassed');
                                      DateTime budgetEndDate =
                                          (state.item.startTime.add(Duration(
                                              seconds:
                                                  numberOfRecurringCyclesPassed *
                                                      recurrenceIntervalSeconds)));
                                      // print('budgetEndDate: ${budgetEndDate.toString()}');
                                      Duration remainingDays = budgetEndDate
                                          .difference(DateTime.now());
                                      // print('remaining days: ${remainingDays.toString()}');
                                      if (remainingDays.inHours < 1) {
                                        return Text(
                                            '${remainingDays.inMinutes} minutes left till new budget',
                                            style: TextStyle(
                                                color: Colors.yellow));
                                      } else if (remainingDays.inDays < 1) {
                                        return Text(
                                            '${remainingDays.inHours} hours left till new budget',
                                            style: TextStyle(
                                                color: Colors.yellow));
                                      } else {
                                        return Text(
                                            '${remainingDays.inDays} days left till new budget',
                                            style:
                                                TextStyle(color: Colors.white));
                                      }
                                    }),
                                  //DateTime budgetEndDate=

                                  if (state.item.frequency is OneTime)
                                    Builder(builder: (context) {
                                      Duration remainingDays = state
                                          .item.endTime
                                          .difference(DateTime.now());
                                      if (remainingDays.inDays > 0 &&
                                          !remainingDays.isNegative) {
                                        return Text(
                                          '${remainingDays.inDays.toString()} days to budget end',
                                          style: TextStyle(color: Colors.white),
                                        );
                                      } else if (remainingDays.isNegative) {
                                        return Text(
                                            'Budget ended ${remainingDays.inDays * -1} days ago');
                                      } else if (remainingDays.inHours > 0 &&
                                          !remainingDays.isNegative) {
                                        return Text(
                                            '${remainingDays.inHours} hours left',
                                            style:
                                                TextStyle(color: Colors.white));
                                      } else if (remainingDays.inMinutes > 0 &&
                                          !remainingDays.isNegative) {
                                        return Text(
                                            '${remainingDays.inMinutes} minutes left',
                                            style: TextStyle(
                                                color: Colors.yellow));
                                      } else {
                                        return Text('');
                                      }
                                    }),
                                  _showAllBudgetExpenses
                                      ? TextButton(
                                          onPressed: () => setState(() =>
                                              _showAllBudgetExpenses = false),
                                          style: ButtonStyle(
                                            foregroundColor:
                                                MaterialStateProperty.all(
                                                    Colors.white),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Icon(Icons.list_alt),
                                              ),
                                              Text("Show Allocations"),
                                            ],
                                          ),
                                        )
                                      : TextButton(
                                          onPressed: () => setState(() =>
                                              _showAllBudgetExpenses = true),
                                          style: ButtonStyle(
                                            foregroundColor:
                                                MaterialStateProperty.all(
                                                    Colors.white),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Icon(
                                                  Icons.list,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text("Show Expenses"),
                                            ],
                                          ),
                                        )
                                ],
                              ),
                            )
                          : CircularProgressIndicator(
                              color: Colors.white,
                            )
                    ],
                  ),
                ),
              ),
            ),
            actions: widget.actionsListBuilder(context, state),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [],
                ),
              ),
            ),
          ),
          _showAllBudgetExpenses
              ? SliverToBoxAdapter(
                  child: BlocProvider(
                    create: (context) => ExpenseListPageBloc(
                      context.read<ExpenseRepository>(),
                      context.read<BudgetRepository>(),
                      context.read<CategoryRepository>(),
                      const DateRangeFilter(
                        "All",
                        DateRange(),
                        FilterLevel.all,
                      ),
                      state.item.id,
                    ),
                    child: BlocBuilder<ExpenseListPageBloc,
                            ExpenseListPageBlocState>(
                        builder: (context, expensesState) {
                      if (expensesState is ExpensesLoadSuccess) {
                        return ExpenseListView(
                          dense: true,
                          items: expensesState.items,
                          allDateRanges: expensesState.dateRangeFilters.values,
                          displayedRange: expensesState.range,
                          loadRange: (range) => context
                              .read<ExpenseListPageBloc>()
                              .add(LoadExpenses(
                                range,
                                ofBudget: state.item.id,
                              )),
                          onEdit: (id) => Navigator.pushNamed(
                            context,
                            ExpenseEditPage.routeName,
                            arguments: expensesState.items[id],
                          ),
                          onDelete: (id) async {
                            final item = expensesState.items[id]!;
                            final confirm = await showDialog<bool?>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirm deletion'),
                                content: Text(
                                  'Are you sure you want to delete entry ${item.name}?',
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Confirm'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm != null && confirm) {
                              context
                                  .read<ExpenseListPageBloc>()
                                  .add(DeleteExpense(id));
                            }
                          },
                        );
                      }
                      return Center(
                          child: CircularProgressIndicator.adaptive());
                    }),
                  ),
                )
              : _perCategoryUsed != null
                  ? BlocBuilder<CategoryListPageBloc,
                      CategoryListPageBlocState>(
                      builder: (context, catListState) {
                        if (catListState is CategoriesLoadSuccess) {
                          // ignore: prefer_collection_literals
                          Set<String> nodes = LinkedHashSet();
                          // ignore: prefer_collection_literals
                          Set<String> rootNodes = LinkedHashSet();
                          for (final id
                              in state.item.categoryAllocations.keys) {
                            final node = catListState.ancestryGraph[id];
                            if (node == null) {
                              throw Exception("unexpected null");
                            }
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
                                    return _catTree(
                                        context,
                                        state,
                                        catListState,
                                        nodes,
                                        _perCategoryUsed!,
                                        item);
                                  }, childCount: rootNodes.length),
                                )
                              : state.item.categoryAllocations.isEmpty
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
                      child:
                          Center(child: CircularProgressIndicator.adaptive()),
                    ),
        ],
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
    if (itemNode == null) {
      return Text("Error: Category under id $id not found in ancestryGraph");
    }

    final children = itemNode.children.where((e) => nodesToShow.contains(e));

    final allocatedAmount = state.item.categoryAllocations[id];
    return Column(
      children: [
        allocatedAmount != null
            ? Builder(builder: (context) {
                final used = perCategoryUsed[id] ?? 0;
                return ListTile(
                  title: Text(item.name, style: TextStyle(fontSize: 18)),
                  subtitle: item.tags.isEmpty
                      ? null
                      : Text(item.tags.map((e) => "#$e").toList().join(" ")),
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
                  /* onTap: () => setState(() {
                    if (_selectedCategory == id) {
                      _selectedCategory = null;
                    } else {
                      _selectedCategory = id;
                    }
                  }),
                  */
                  onTap: () => Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) =>
                          _BudgetDetailsCategoryAllocationDisplay(
                        budget: state.item,
                        category: item,
                        usedAllocation: used,
                      ),
                    ),
                  ),
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
                                        FilterLevel.all,
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
                                                .add(
                                                  LoadExpenses(range,
                                                      ofBudget: state.item.id,
                                                      ofCategory: item.id),
                                                )),
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
                if (children.isNotEmpty)
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

  Widget _categoryAllocationDetails(
    BuildContext context,
    LoadSuccess<String, Budget> state,
  ) {
    final currency = state.item.allocatedAmount.currency;
    final used = _perCategoryUsed![_selectedCategory]!;
    final allocated = state.item.categoryAllocations[_selectedCategory]!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            toolbarHeight: 60,
            title: Text(state.item.name),
            expandedHeight: 250,
            pinned: true,
            shape: RoundedRectangleBorder(
              side: BorderSide.none,
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(30)),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 60,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.1,
                        child: Center(
                          child: IconButton(
                            onPressed: () =>
                                setState(() => _selectedCategory = null),
                            icon: Icon(
                              Icons.chevron_left_outlined,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      _totalUsed != null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...<dynamic>[
                                  ['Used', "${used / 100}", used > allocated],
                                  [
                                    'Remaining',
                                    "${(allocated - used) / 100}",
                                    used > allocated
                                  ],
                                  ['Allocated', "${allocated / 100}", false],
                                ].map(((e) => DefaultTextStyle(
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(e[0]),
                                          DefaultTextStyle(
                                            style: const TextStyle(
                                              fontSize: 20,
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  "$currency ",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w200),
                                                ),
                                                Text(
                                                  e[1],
                                                  style: TextStyle(
                                                    backgroundColor: e[2]
                                                        ? Colors.red[700]
                                                        : null,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))),
                              ],
                            )
                          : CircularProgressIndicator(
                              color: Colors.white,
                            ),
                      _totalUsed != null
                          ? Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                // crossAxisAlignment: CrossAxisAlignment.start?,
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: DefaultTextStyle(
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 44,
                                          ),
                                          child: allocated == 0
                                              ? Text("0%")
                                              : Builder(builder: (context) {
                                                  final percentage =
                                                      ((used / allocated) * 100)
                                                          .truncate();
                                                  return FittedBox(
                                                    child: Text(
                                                      "$percentage%",
                                                      style: percentage >= 100
                                                          ? TextStyle(
                                                              backgroundColor:
                                                                  Colors
                                                                      .red[700],
                                                            )
                                                          : null,
                                                    ),
                                                  );
                                                })),
                                    ),
                                  ),
                                  _showAllBudgetExpenses
                                      ? TextButton(
                                          onPressed: () => setState(() =>
                                              _showAllBudgetExpenses = false),
                                          style: ButtonStyle(
                                            foregroundColor:
                                                MaterialStateProperty.all(
                                                    Colors.white),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Icon(Icons.list_alt),
                                              ),
                                              Text("Show Allocations"),
                                            ],
                                          ),
                                        )
                                      : TextButton(
                                          onPressed: () => setState(() =>
                                              _showAllBudgetExpenses = true),
                                          style: ButtonStyle(
                                            foregroundColor:
                                                MaterialStateProperty.all(
                                                    Colors.white),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Icon(
                                                  Icons.list,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text("Show Expenses"),
                                            ],
                                          ),
                                        )
                                ],
                              ),
                            )
                          : CircularProgressIndicator(
                              color: Colors.white,
                            )
                    ],
                  ),
                ),
              ),
            ),
            actions: widget.actionsListBuilder(context, state),
          ),
          SliverToBoxAdapter(
              child: BlocProvider(
                  create: (context) => ExpenseListPageBloc(
                        context.read<ExpenseRepository>(),
                        context.read<BudgetRepository>(),
                        context.read<CategoryRepository>(),
                        const DateRangeFilter(
                          "All",
                          DateRange(),
                          FilterLevel.all,
                        ),
                        state.item.id,
                        _selectedCategory,
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
                                  categoryId: _selectedCategory!),
                            ),
                          )),
                          ExpenseListView(
                              dense: true,
                              items: expensesState.items,
                              allDateRanges:
                                  expensesState.dateRangeFilters.values,
                              displayedRange: expensesState.range,
                              loadRange: (range) =>
                                  context.read<ExpenseListPageBloc>().add(
                                        LoadExpenses(range,
                                            ofBudget: state.item.id,
                                            ofCategory: _selectedCategory),
                                      )),
                        ],
                      );
                    }
                    return Center(child: CircularProgressIndicator.adaptive());
                  }))),
        ],
      ),
    );
  }
}

class _BudgetDetailsCategoryAllocationDisplay extends StatelessWidget {
  final Budget budget;
  final Category category;
  final int usedAllocation;

  const _BudgetDetailsCategoryAllocationDisplay({
    Key? key,
    required this.budget,
    required this.category,
    required this.usedAllocation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currency = budget.allocatedAmount.currency;
    final allocated = budget.categoryAllocations[category.id]!;
    final used = usedAllocation;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            toolbarHeight: 60,
            title: Text(budget.name),
            expandedHeight: 250,
            pinned: true,
            shape: RoundedRectangleBorder(
              side: BorderSide.none,
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(30)),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 60,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.1,
                        child: Center(
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.chevron_left_outlined,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              category.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: Colors.white),
                            ),
                            Row(
                              children: [
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ...<List<dynamic>>[
                                      [
                                        'Used',
                                        "${used / 100}",
                                        used > allocated
                                      ],
                                      [
                                        'Remaining',
                                        "${(allocated - used) / 100}",
                                        used > allocated
                                      ],
                                      [
                                        'Allocated',
                                        "${allocated / 100}",
                                        false
                                      ],
                                    ].map(
                                      ((e) => DefaultTextStyle(
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(e[0]),
                                                DefaultTextStyle(
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        "$currency ",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w200),
                                                      ),
                                                      Text(
                                                        e[1],
                                                        style: TextStyle(
                                                          backgroundColor: e[2]
                                                              ? Colors.red[700]
                                                              : null,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )),
                                    )
                                  ],
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    // crossAxisAlignment: CrossAxisAlignment.start?,
                                    children: [
                                      Expanded(
                                        child: Center(
                                          child: DefaultTextStyle(
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 44,
                                              ),
                                              child: allocated == 0
                                                  ? Text("0%")
                                                  : Builder(builder: (context) {
                                                      final percentage =
                                                          ((used / allocated) *
                                                                  100)
                                                              .truncate();
                                                      return FittedBox(
                                                        child: Text(
                                                          "$percentage%",
                                                          style:
                                                              percentage >= 100
                                                                  ? TextStyle(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .red[700],
                                                                    )
                                                                  : null,
                                                        ),
                                                      );
                                                    })),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
              child: BlocProvider(
                  create: (context) => ExpenseListPageBloc(
                        context.read<ExpenseRepository>(),
                        context.read<BudgetRepository>(),
                        context.read<CategoryRepository>(),
                        const DateRangeFilter(
                          "All",
                          DateRange(),
                          FilterLevel.all,
                        ),
                        budget.id,
                        category.id,
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
                                budgetId: budget.id,
                                categoryId: category.id,
                              ),
                            ),
                          )),
                          ExpenseListView(
                              dense: true,
                              items: expensesState.items,
                              allDateRanges:
                                  expensesState.dateRangeFilters.values,
                              displayedRange: expensesState.range,
                              loadRange: (range) =>
                                  context.read<ExpenseListPageBloc>().add(
                                        LoadExpenses(
                                          range,
                                          ofBudget: budget.id,
                                          ofCategory: category.id,
                                        ),
                                      )),
                        ],
                      );
                    }
                    return Center(child: CircularProgressIndicator.adaptive());
                  }))),
        ],
      ),
    );
  }
}
/*
class SlidingAnimatedRoute extends CupertinoPageRoute {
  SlidingAnimatedRoute({
    required Widget Function(BuildContext) builder,
    String? title,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) : super(
            builder: builder,
            title: title,
            settings: settings,
            maintainState: maintainState,
            fullscreenDialog: fullscreenDialog);
  @override
  Widget buildPage(context, animation, secondaryAnimation) =>
      SlideTransition(position:animation);
}
 */
