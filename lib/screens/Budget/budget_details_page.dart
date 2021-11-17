import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/screens/Expense/expense_edit_page.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni/widgets/widgets.dart';

import 'budget_edit_page.dart';

class BudgetDetailsPage extends StatefulWidget {
  static const String routeName = "budgetDetails";

  static Route route(String id) => MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (context) => BudgetDetailsPage.page(id),
      );

  static Widget page(
    String id, [
    List<Widget> Function(BuildContext, BudgetLoadSuccess) actionsListBuilder =
        defaultActionsListBuilder,
  ]) =>
      MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (BuildContext context) => BudgetDetailsPageBloc(
                  context.read<BudgetRepository>(),
                  context.read<OfflineBudgetRepository>(),
                  context.read<AuthBloc>(),
                  context.read<ExpenseRepository>(),
                  context.read<OfflineExpenseRepository>(),
                  context.read<SyncBloc>(),
                  id),
            ),
            BlocProvider(
              create: (BuildContext context) => CategoryListPageBloc(
                context.read<CategoryRepository>(),
                context.read<OfflineCategoryRepository>(),
                LoadCategoriesFilter(
                  includeActive: true,
                  includeArchvied: true,
                ),
              ),
            ),
          ],
          child: BudgetDetailsPage(
            actionsListBuilder: actionsListBuilder,
          ));

  static Widget _dialogActionButton(
    BuildContext context,
    BudgetLoadSuccess state, {
    required String butonTitle,
    required String dialogTitle,
    required String dialogContent,
    required String cancelButtonTitle,
    required String confirmButtonTitle,
    required BudgetDetailsPageEvent Function({
      OperationSuccessNotifier? onSuccess,
      OperationExceptionNotifier? onError,
    })
        eventGenerator,
  }) =>
      TextButton(
        child: Text(butonTitle, style: TextStyle(color: Colors.white)),
        onPressed: () async {
          final confirm = await showDialog<bool?>(
            context: context,
            builder: (_) {
              var awaitingOp = false;
              return StatefulBuilder(
                builder: (dialogContext, setState) => AlertDialog(
                  title: Text(dialogTitle),
                  content: Text(dialogContent),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: Text(cancelButtonTitle),
                    ),
                    TextButton(
                      onPressed: !awaitingOp
                          ? () {
                              context
                                  .read<BudgetDetailsPageBloc>()
                                  .add(eventGenerator(
                                    onSuccess: () {
                                      setState(() => awaitingOp = false);
                                      Navigator.pop(dialogContext, true);
                                    },
                                    onError: (err) {
                                      setState(() => awaitingOp = false);
                                      if (err is SyncException) {
                                        Navigator.pop(dialogContext, false);
                                        Navigator.popUntil(
                                          context,
                                          (route) => route.isFirst,
                                        );
                                      } else {
                                        ScaffoldMessenger.of(dialogContext)
                                            .showSnackBar(
                                          SnackBar(
                                            content: err is ConnectionException
                                                ? Text('Connection Failed')
                                                : err is UnseenVersionException
                                                    ? Text(
                                                        'Desync error: sync first',
                                                      )
                                                    : Text(
                                                        'Unknown Error Occured'),
                                            behavior: SnackBarBehavior.floating,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                  ));
                              setState(() => awaitingOp = true);
                            }
                          : null,
                      child: !awaitingOp
                          ? Text(confirmButtonTitle)
                          : const CircularProgressIndicator(),
                    ),
                  ],
                ),
              );
            },
          );
          if (confirm != null && confirm) {
            Navigator.pop(context);
          }
        },
      );

  static List<Widget> defaultActionsListBuilder(
    BuildContext context,
    BudgetLoadSuccess state,
  ) =>
      state.item.isArchived
          ? [
              _dialogActionButton(
                context,
                state,
                butonTitle: "Restore",
                dialogTitle: "Confirm",
                dialogContent:
                    "Are you sure you want to restore budget ${state.item.name}?",
                cancelButtonTitle: "Cancel",
                confirmButtonTitle: "Restore",
                eventGenerator: ({onError, onSuccess}) => UnarchiveBudget(
                  onSuccess: onSuccess,
                  onError: onError,
                ),
              ),
              _dialogActionButton(
                context,
                state,
                butonTitle: "Permanent Delete",
                dialogTitle: "Confirm deletion",
                dialogContent:
                    "Are you sure you want to permanently delete entry ${state.item.name}?"
                    "\nWARNING: All attached expenses will be removed as well.",
                cancelButtonTitle: "Cancel",
                confirmButtonTitle: "Delete",
                eventGenerator: ({onError, onSuccess}) => DeleteBudget(
                  onSuccess: onSuccess,
                  onError: onError,
                ),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  BudgetEditPage.routeName,
                  arguments: state.item,
                ),
                child: const Text("Edit",style: TextStyle(color:Colors.white),),
              ),
              _dialogActionButton(
                context,
                state,
                butonTitle: "Delete",
                dialogTitle: "Confirm delete",
                dialogContent:
                    "Are you sure you want to delete entry ${state.item.name}?"
                    "\nAssociated expense entries won't removed and you can always recover it afterwards.",
                cancelButtonTitle: "Cancel",
                confirmButtonTitle: "Delete",
                eventGenerator: ({onError, onSuccess}) => ArchiveBudget(
                  onSuccess: onSuccess,
                  onError: onError,
                ),
              ),
            ];

  final List<Widget> Function(BuildContext, BudgetLoadSuccess)
      actionsListBuilder;

  BudgetDetailsPage(
      {Key? key, this.actionsListBuilder = defaultActionsListBuilder})
      : super(key: key);

  @override
  State<BudgetDetailsPage> createState() => _BudgetDetailsPageState();
}

class _BudgetDetailsPageState extends State<BudgetDetailsPage> {
  String? _selectedCategory;

  var _showAllBudgetExpenses = false;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<BudgetDetailsPageBloc, BudgetDetailsPageState>(
        builder: (context, state) {
          if (state is BudgetLoadSuccess) {
            return _details(context, state);
          } else if (state is LoadingBudget) {
            return Scaffold(
              appBar: AppBar(
                title: const Text("Loading budget..."),
              ),
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (state is BudgetNotFound) {
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
    BudgetLoadSuccess state,
  ) {
    final currency = state.item.allocatedAmount.currency;
    final totalAllocated = state.item.allocatedAmount.amount;

    return Scaffold(
      body: BlocProvider(
        create: (BuildContext context) => ExpenseListPageBloc(
          context.read<ExpenseRepository>(),
          context.read<OfflineExpenseRepository>(),
          context.read<AuthBloc>(),
          context.read<BudgetRepository>(),
          context.read<CategoryRepository>(),
          initialFilter: LoadExpensesFilter(
              ofBudget: state.id,
              range: state.item.frequency is Recurring
                  ? currentBudgetCycle(state.item.frequency as Recurring,
                      state.item.startTime, state.item.endTime, DateTime.now())
                  : DateRangeFilter("All", DateRange(), FilterLevel.all)),
        ),
        child: BlocBuilder<ExpenseListPageBloc, ExpenseListPageBlocState>(
          builder: (context, expensesState) => expensesState
                  is ExpensesLoadSuccess
              ? BlocBuilder<CategoryListPageBloc, CategoryListPageBlocState>(
                  builder: (context, catListState) => catListState
                          is CategoriesLoadSuccess
                      ? Builder(builder: (context) {
                          var totalUsed = 0;
                          final perCategoryUsed = <String, int>{};
                          for (final expense in expensesState.items.values) {
                            final expenseAmount = expense.amount.amount;
                            totalUsed += expenseAmount;
                            perCategoryUsed.update(
                              expense.categoryId,
                              (value) => value + expenseAmount,
                              ifAbsent: () => expenseAmount,
                            );
                          }
                          return CustomScrollView(
                            slivers: [
                              _detailsAppBar(
                                context,
                                state,
                                totalAllocated,
                                currency,
                                totalUsed,
                              ),
                              if (!_showAllBudgetExpenses &&
                                  state.item.frequency is Recurring)
                                SliverToBoxAdapter(
                                  child: Container(
                                    height: 50,
                                    child: Builder(builder: (context) {
                                      final allRange = DateRangeFilter(
                                          "All", DateRange(), FilterLevel.all);
                                      final cycleRanges = pastCycleDateRanges(
                                        state.item.frequency as Recurring,
                                        state.item.startTime,
                                        state.item.endTime,
                                        DateTime.now(),
                                      );
                                      Widget tabButton(DateRangeFilter range) =>
                                          ExpenseListView.buttonChip(
                                            range.name,
                                            isSelected: expensesState
                                                    .filter.range.range ==
                                                range.range,
                                            isIncluded: expensesState
                                                .filter.range.range
                                                .contains(range.range),
                                            onPressed: () => context
                                                .read<ExpenseListPageBloc>()
                                                .add(LoadExpenses(
                                                    filter: LoadExpensesFilter(
                                                  range: range,
                                                  ofBudget: state.id,
                                                ))),
                                          );
                                      print(
                                          "a: ${cycleRanges[0]}\n b: ${expensesState.filter.range}");
                                      return ListView(
                                        scrollDirection: Axis.horizontal,
                                        children: [
                                          // All expenses button
                                          tabButton(allRange),
                                          ...cycleRanges.map(tabButton),
                                        ],
                                      );
                                    }),
                                  ),
                                ),
                              _showAllBudgetExpenses
                                  ? _allBudgetExpenses(context, state,
                                      expensesState, catListState)
                                  : _categoryAllocations(
                                      context,
                                      state,
                                      expensesState,
                                      catListState,
                                      perCategoryUsed,
                                    )
                            ],
                          );
                        })
                      : catListState is CategoriesLoading
                          ? Center(child: CircularProgressIndicator())
                          : throw Exception("Unhandled state: $catListState"),
                )
              : expensesState is ExpensesLoading
                  ? Center(child: CircularProgressIndicator())
                  : throw Exception("Unhandled state: $expensesState"),
        ),
      ),
      floatingActionButton: Visibility(
        visible: _selectedCategory == null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ...defaultActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _detailsAppBar(
    BuildContext context,
    BudgetLoadSuccess state,
    int totalAllocated,
    String currency,
    int totalUsed,
  ) =>
      SliverAppBar(
        toolbarHeight: 60,
        title: FittedBox(child: Text(state.item.name)),
        shape: RoundedRectangleBorder(
          side: BorderSide.none,
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30)),
        ),
        expandedHeight: 250,
        pinned: true, backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        //floating: true,
        flexibleSpace: DefaultTextStyle(
          style: const TextStyle(
            color: Colors.white,
          ),
          child: FlexibleSpaceBar(
            background: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 60, 0, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...<dynamic>[
                          [
                            'Used',
                            "${totalUsed / 100}",
                            totalUsed > totalAllocated
                          ],
                          [
                            'Remaining',
                            "${(totalAllocated - totalUsed) / 100}",
                            totalUsed > totalAllocated
                          ],
                          ['Total', "${totalAllocated / 100}", false],
                        ].map(((e) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                            fontWeight: FontWeight.w200),
                                      ),
                                      Text(
                                        e[1],
                                        style: TextStyle(
                                          backgroundColor:
                                              e[2] ? Colors.red[700] : null,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ))),
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
                                    fontSize: 44,
                                  ),
                                  child: totalAllocated == 0
                                      ? Text("0%")
                                      : Builder(builder: (context) {
                                          final percentage =
                                              ((totalUsed / totalAllocated) *
                                                      100)
                                                  .truncate();
                                          return FittedBox(
                                            child: Text(
                                              "$percentage%",
                                              style: percentage >= 100
                                                  ? TextStyle(
                                                      backgroundColor:
                                                          Colors.red[700],
                                                    )
                                                  : null,
                                            ),
                                          );
                                        })),
                            ),
                          ),
                          if (state.item.frequency is Recurring)
                            Builder(builder: (context) {
                              int recurrenceIntervalSeconds =
                                  (state.item.frequency as Recurring)
                                      .recurringIntervalSecs;
                              int untilNow = DateTime.now()
                                  .difference(state.item.startTime)
                                  .inSeconds;
                              int numberOfRecurringCyclesPassed =
                                  (untilNow / recurrenceIntervalSeconds).ceil();
                              DateTime budgetEndDate = (state.item.startTime
                                  .add(Duration(
                                      seconds: numberOfRecurringCyclesPassed *
                                          recurrenceIntervalSeconds)));
                              Duration remainingDays =
                                  budgetEndDate.difference(DateTime.now());
                              if (remainingDays.inHours < 1) {
                                return Text(
                                    '${remainingDays.inMinutes} minutes left till new cycle',
                                    style: TextStyle(color: Colors.yellow));
                              } else if (remainingDays.inDays < 1) {
                                return Text(
                                    '${remainingDays.inHours} hours left till new cycle',
                                    style: TextStyle(color: Colors.yellow));
                              } else {
                                return Text(
                                    '${remainingDays.inDays} days left till new cycle');
                              }
                            }),
                          if (state.item.frequency is OneTime)
                            Builder(builder: (context) {
                              Duration remainingDays =
                                  state.item.endTime.difference(DateTime.now());
                              if (remainingDays.inDays > 0 &&
                                  !remainingDays.isNegative) {
                                return Text(
                                  '${remainingDays.inDays.toString()} days to budget end',
                                );
                              } else if (remainingDays.isNegative) {
                                return Text(
                                    'Budget ended ${remainingDays.inDays * -1} days ago');
                              } else if (remainingDays.inHours > 0 &&
                                  !remainingDays.isNegative) {
                                return Text(
                                    '${remainingDays.inHours} hours left');
                              } else if (remainingDays.inMinutes > 0 &&
                                  !remainingDays.isNegative) {
                                return Text(
                                    '${remainingDays.inMinutes} minutes left',
                                    style: TextStyle(color: Colors.yellow));
                              } else {
                                return Text('');
                              }
                            }),
                          _showAllBudgetExpenses
                              ? TextButton(
                                  onPressed: () => setState(
                                      () => _showAllBudgetExpenses = false),
                                  style: ButtonStyle(
                                    foregroundColor:
                                        MaterialStateProperty.all(Colors.white),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                  onPressed: () => setState(
                                      () => _showAllBudgetExpenses = true),
                                  style: ButtonStyle(
                                    foregroundColor:
                                        MaterialStateProperty.all(Colors.white),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: widget.actionsListBuilder(context, state),
      );

  Widget _allBudgetExpenses(
    BuildContext context,
    BudgetLoadSuccess state,
    ExpensesLoadSuccess allExpensesState,
    CategoriesLoadSuccess catListState,
  ) =>
      SliverToBoxAdapter(
        child: MultiBlocProvider(
          providers: [
            // use a separate expenses bloc for range load
            BlocProvider(
              create: (context) => ExpenseListPageBloc(
                context.read<ExpenseRepository>(),
                context.read<OfflineExpenseRepository>(),
                context.read<AuthBloc>(),
                context.read<BudgetRepository>(),
                context.read<CategoryRepository>(),
                initialFilter: LoadExpensesFilter(ofBudget: state.item.id),
              ),
            ),
            BlocProvider(
              create: (context) => BudgetListPageBloc(
                context.read<BudgetRepository>(),
                context.read<OfflineBudgetRepository>(),
                LoadBudgetsFilter(
                  includeActive: true,
                  includeArchvied: true,
                ),
              ),
            ),
          ],
          child: BlocBuilder<ExpenseListPageBloc, ExpenseListPageBlocState>(
            builder: (context, expensesState) => expensesState
                    is ExpensesLoadSuccess
                ? BlocBuilder<BudgetListPageBloc, BudgetListPageBlocState>(
                    builder: (context, budgetsState) => budgetsState
                            is BudgetsLoadSuccess
                        ? SingleChildScrollView(
                            child: ExpenseListView(
                              dense: true,
                              items: expensesState.items,
                              allBudgets: budgetsState.items,
                              allCategories: catListState.items,
                              allDateRanges:
                                  expensesState.dateRangeFilters.values,
                              unbucketedRanges:
                                  state.item.frequency is Recurring
                                      ? pastCycleDateRanges(
                                          state.item.frequency as Recurring,
                                          state.item.startTime,
                                          state.item.endTime,
                                          DateTime.now(),
                                        )
                                      : [],
                              displayedRange: expensesState.filter.range,
                              showBudgetDetail: false,
                              loadRange: (range) => context
                                  .read<ExpenseListPageBloc>()
                                  .add(LoadExpenses(
                                    filter: LoadExpensesFilter(
                                      range: range,
                                      ofBudget: state.item.id,
                                    ),
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
                            ),
                          )
                        : budgetsState is BudgetsLoading
                            ? Center(
                                child: CircularProgressIndicator.adaptive())
                            : throw Exception("Unhandled state: $budgetsState"),
                  )
                : expensesState is ExpensesLoading
                    ? Center(child: CircularProgressIndicator.adaptive())
                    : throw Exception("Unhandled state: $expensesState"),
          ),
        ),
      );

  Widget _categoryAllocations(
    BuildContext context,
    BudgetLoadSuccess state,
    ExpensesLoadSuccess expensesState,
    CategoriesLoadSuccess catListState,
    Map<String, int> perCategoryUsed,
  ) {
    // FIXME: move this calculation out of the buld method
    final ancestryTree = CategoryRepositoryExt.calcAncestryTree(
      // build tree from used as well as allocation
      // to catch misc and other unallocated category
      // expenses
      perCategoryUsed.keys
          .toSet()
          .union(state.item.categoryAllocations.keys.toSet()),
      catListState.items,
    );

    // ignore: prefer_collection_literals
    Set<String> rootNodes = LinkedHashSet();
    for (final node in ancestryTree.values.where((e) => e.parent == null)) {
      rootNodes.add(node.item);
    }

    return rootNodes.isNotEmpty
        ? SliverPadding(
            padding: const EdgeInsets.all(8.0),
            sliver: SliverList(
              delegate:
                  SliverChildBuilderDelegate((BuildContext context, int index) {
                final id = rootNodes.elementAt(index);
                return _catTree(
                  context,
                  state,
                  catListState.items,
                  ancestryTree,
                  perCategoryUsed,
                  id,
                );
              }, childCount: rootNodes.length),
            ),
          )
        : state.item.categoryAllocations.isEmpty
            ? SliverFillRemaining(
                child: Center(child: const Text("No categories.")))
            : throw Exception("error: parents are missing");
  }

  Widget _catTree(
    BuildContext context,
    BudgetLoadSuccess state,
    Map<String, Category> allItems,
    Map<String, TreeNode<String>> nodes,
    Map<String, int> perCategoryUsed,
    String id,
  ) {
    final item = allItems[id];
    final itemNode = nodes[id];
    if (item == null) return Text("Error: Category under id $id not found");
    if (itemNode == null) {
      return Text("Error: Category under id $id not found in ancestryGraph");
    }

    final allocatedAmount = state.item.categoryAllocations[id] ?? 0;
    final used = perCategoryUsed[id] ?? 0;

    return Column(
      children: [
        allocatedAmount > 0 || used > 0
            ? ListTile(
                selected: _selectedCategory == id,
                title: Text(item.name),
                subtitle: item.tags.isNotEmpty || item.isArchived
                    ? Row(children: [
                        if (item.isArchived)
                          Text("In Trash", style: TextStyle(color: Colors.red)),
                        if (item.isArchived && item.tags.isNotEmpty)
                          const DotSeparator(),
                        if (item.tags.isNotEmpty)
                          Text(item.tags.map((e) => "#$e").toList().join(" ")),
                      ])
                    : null,
                trailing: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      allocatedAmount > 0
                          ? Text("${used / 100} / ${allocatedAmount / 100}")
                          : Text("${used / 100}"),
                      allocatedAmount > 0
                          ? LinearProgressIndicator(
                              minHeight: 8,
                              value: used / allocatedAmount,
                              color: used > allocatedAmount ? Colors.red : null,
                            )
                          : Text(
                              "Not allocated",
                              style: TextStyle(color: Colors.grey),
                            ),
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
              )
            : ListTile(
                dense: true,
                title: Text(item.name),
              ),
        if (_selectedCategory == id)
          Container(
            decoration: BoxDecoration(
              border: Border.all(),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(25)),
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (!item.isArchived)
                    TextButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        ExpenseEditPage.routeName,
                        arguments: ExpenseEditPageNewArgs(
                            budgetId: state.item.id, categoryId: item.id),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text("New expense"),
                    ),
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) =>
                            _BudgetDetailsCategoryAllocationDisplay.page(
                          budget: state.item,
                          category: item,
                          usedAllocation: used,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.list),
                    label: const Text("Details"),
                  ),
                ]),
          ),
        if (itemNode.children.isNotEmpty)
          Padding(
            padding:
                EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.05),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ...itemNode.children.map(
                  (e) => _catTree(
                    context,
                    state,
                    allItems,
                    nodes,
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

class _BudgetDetailsCategoryAllocationDisplay extends StatelessWidget {
  final Budget budget;
  final Category category;
  const _BudgetDetailsCategoryAllocationDisplay._({
    Key? key,
    required this.budget,
    required this.category,
  }) : super(key: key);

  static Widget page({
    Key? key,
    required Budget budget,
    required Category category,
    required int usedAllocation,
  }) =>
      MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => BudgetListPageBloc(
              context.read<BudgetRepository>(),
              context.read<OfflineBudgetRepository>(),
              LoadBudgetsFilter(
                includeActive: true,
                includeArchvied: true,
              ),
            ),
          ),
          BlocProvider(
            create: (BuildContext context) => ExpenseListPageBloc(
              context.read<ExpenseRepository>(),
              context.read<OfflineExpenseRepository>(),
              context.read<AuthBloc>(),
              context.read<BudgetRepository>(),
              context.read<CategoryRepository>(),
              initialFilter: LoadExpensesFilter(
                ofBudget: budget.id,
                ofCategory: category.id,
                range: budget.frequency is Recurring
                    ? currentBudgetCycle(
                        budget.frequency as Recurring,
                        budget.startTime,
                        budget.endTime,
                        DateTime.now(),
                      )
                    : DateRangeFilter("All", DateRange(), FilterLevel.all),
              ),
            ),
          ),
          BlocProvider(
            create: (BuildContext context) => CategoryListPageBloc(
              context.read<CategoryRepository>(),
              context.read<OfflineCategoryRepository>(),
              LoadCategoriesFilter(
                includeActive: true,
                includeArchvied: true,
              ),
            ),
          ),
        ],
        child: _BudgetDetailsCategoryAllocationDisplay._(
          key: key,
          budget: budget,
          category: category,
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: BlocBuilder<ExpenseListPageBloc, ExpenseListPageBlocState>(
          builder: (context, expensesState) {
            return expensesState is ExpensesLoadSuccess
                ? CustomScrollView(
                    slivers: [
                      _appBar(context, expensesState),
                      SliverToBoxAdapter(
                        child: BlocBuilder<BudgetListPageBloc,
                            BudgetListPageBlocState>(
                          builder: (context, budgetsState) => budgetsState
                                  is BudgetsLoadSuccess
                              ? BlocBuilder<CategoryListPageBloc,
                                  CategoryListPageBlocState>(
                                  builder: (context, categoriesState) =>
                                      categoriesState is CategoriesLoadSuccess
                                          ? SingleChildScrollView(
                                              child: ExpenseListView(
                                                  dense: true,
                                                  items: expensesState.items,
                                                  allBudgets:
                                                      budgetsState.items,
                                                  allCategories:
                                                      categoriesState.items,
                                                  allDateRanges: expensesState
                                                      .dateRangeFilters.values,
                                                  displayedRange: expensesState
                                                      .filter.range,
                                                  unbucketedRanges:
                                                      budget.frequency
                                                              is Recurring
                                                          ? pastCycleDateRanges(
                                                              budget.frequency
                                                                  as Recurring,
                                                              budget.startTime,
                                                              budget.endTime,
                                                              DateTime.now(),
                                                            )
                                                          : [],
                                                  showBudgetDetail: false,
                                                  showCategoryDetail: false,
                                                  loadRange: (range) => context
                                                      .read<
                                                          ExpenseListPageBloc>()
                                                      .add(
                                                        LoadExpenses(
                                                            filter:
                                                                LoadExpensesFilter(
                                                          range: range,
                                                          ofBudget: budget.id,
                                                          ofCategory:
                                                              category.id,
                                                        )),
                                                      )),
                                            )
                                          : categoriesState is CategoriesLoading
                                              ? Center(
                                                  child:
                                                      CircularProgressIndicator
                                                          .adaptive())
                                              : throw Exception(
                                                  "Unhandled state: $categoriesState"),
                                )
                              : budgetsState is BudgetsLoading
                                  ? Center(
                                      child:
                                          CircularProgressIndicator.adaptive())
                                  : throw Exception(
                                      "Unhandled state: $budgetsState"),
                        ),
                      ),
                    ],
                  )
                : expensesState is ExpensesLoading
                    ? Center(child: CircularProgressIndicator.adaptive())
                    : throw Exception("Unhandled state: $expensesState");
          },
        ),
        floatingActionButton: Visibility(
            child: FloatingActionButton.extended(
                onPressed: () => Navigator.pushNamed(
                      context,
                      ExpenseEditPage.routeName,
                      arguments: ExpenseEditPageNewArgs(
                        budgetId: budget.id,
                        categoryId: category.id,
                      ),
                    ),
                label: Text('Add new expense'),
                icon: Icon(Icons.add)),
            visible: !category.isArchived ? true : false),
      );

  SliverAppBar _appBar(
    BuildContext context,
    ExpensesLoadSuccess expensesState,
  ) {
    var used = 0;
    for (final expense in expensesState.items.values) {
      final expenseAmount = expense.amount.amount;
      used += expenseAmount;
    }
    final currency = budget.allocatedAmount.currency;
    final allocated = budget.categoryAllocations[category.id];

    return SliverAppBar(
      toolbarHeight: 60,
      title: Text(budget.name),
      expandedHeight: 250,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide.none,
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(30)),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.white),
            child: Padding(
              padding: const EdgeInsets.only(top: 60, left: 16, right: 16),
              child: allocated != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // usage column
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        ((e) => Padding(
                                              padding:
                                                  const EdgeInsets.all(3.0),
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
                                                            backgroundColor: e[
                                                                    2]
                                                                ? Colors
                                                                    .red[700]
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
                                ],
                              ),
                            ],
                          ),
                        ),
                        // precentage column
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          // crossAxisAlignment: CrossAxisAlignment.start?,
                          children: [
                            Text(
                              category.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            if (budget.allocatedAmount.amount > 0)
                              Text(
                                  "Allocated ${(((allocated * 100) / budget.allocatedAmount.amount)).truncate()}% of budget"),
                            Center(
                              child: DefaultTextStyle(
                                  style: const TextStyle(fontSize: 44),
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
                                                          Colors.red[700],
                                                    )
                                                  : null,
                                            ),
                                          );
                                        })),
                            ),
                          ],
                        )
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.white,
                                  size: 13,
                                ),
                                Text(
                                  "This category is unallocated for.",
                                  textScaleFactor: 0.9,
                                ),
                              ],
                            ),
                            Text(
                              category.name,
                              textScaleFactor: 2,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Used"),
                            DefaultTextStyle(
                              style: const TextStyle(
                                // color: Colors.white,
                                fontSize: 33,
                              ),
                              child: FittedBox(
                                  alignment: Alignment.topLeft,
                                  child: Row(
                                    children: [
                                      Text(
                                        "$currency ",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w200),
                                      ),
                                      Text("${used / 100}"),
                                    ],
                                  )),
                            ),
                          ],
                        )
                      ],
                    ),
            ),
          ),
        ),
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
