import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni/widgets/widgets.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

class ExpenseEditPageNewArgs {
  final String budgetId;
  final String? categoryId;

  const ExpenseEditPageNewArgs({required this.budgetId, this.categoryId});
}

class ExpenseEditPage extends StatefulWidget {
  static const String routeName = "/expenseEdit";
  const ExpenseEditPage({
    Key? key,
    required this.item,
    required this.isCreating,
  }) : super(key: key);

  static Route route(Expense item) => MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (BuildContext context) => BudgetDetailsPageBloc(
                  context.read<BudgetRepository>(),
                  context.read<OfflineBudgetRepository>(),
                  context.read<AuthBloc>(),
                  context.read<ExpenseRepository>(),
                  context.read<OfflineExpenseRepository>(),
                  context.read<SyncBloc>(),
                  item.budgetId),
            ),
            BlocProvider(
              create: (BuildContext context) => ExpenseListPageBloc(
                context.read<ExpenseRepository>(),
                context.read<OfflineExpenseRepository>(),
                context.read<AuthBloc>(),
                context.read<BudgetRepository>(),
                context.read<CategoryRepository>(),
                initialFilter: LoadExpensesFilter(ofBudget: item.budgetId),
              ),
            ),
            BlocProvider(
              create: (BuildContext context) => CategoryListPageBloc(
                context.read<CategoryRepository>(),
                context.read<OfflineCategoryRepository>(),
              ),
            ),
            BlocProvider(
              create: (BuildContext context) => CategoryListPageBloc(
                context.read<CategoryRepository>(),
                context.read<OfflineCategoryRepository>(),
              ),
            ),
            BlocProvider(
              create: (context) => ExpenseEditPageBloc(
                context.read<ExpenseRepository>(),
                context.read<OfflineExpenseRepository>(),
                context.read<AuthBloc>(),
              ),
            ),
          ],
          child: ExpenseEditPage(
            item: item,
            isCreating: false,
          ),
        ),
      );

  static Route routeNew(ExpenseEditPageNewArgs args) => MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) {
        final now = DateTime.now();

        final item = Expense(
          id: "id-${now.microsecondsSinceEpoch}",
          createdAt: now,
          updatedAt: now,
          name: humanReadableDateTime(now),
          timestamp: now,
          categoryId: args.categoryId ??
              context
                  .read<PreferencesBloc>()
                  .preferencesLoadSuccessState()
                  .preferences
                  .miscCategory,
          budgetId: args.budgetId,
          amount: MonetaryAmount(currency: "ETB", amount: 0),
        );
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (BuildContext context) => BudgetDetailsPageBloc(
                  context.read<BudgetRepository>(),
                  context.read<OfflineBudgetRepository>(),
                  context.read<AuthBloc>(),
                  context.read<ExpenseRepository>(),
                  context.read<OfflineExpenseRepository>(),
                  context.read<SyncBloc>(),
                  args.budgetId),
            ),
            BlocProvider(
              create: (BuildContext context) => ExpenseListPageBloc(
                context.read<ExpenseRepository>(),
                context.read<OfflineExpenseRepository>(),
                context.read<AuthBloc>(),
                context.read<BudgetRepository>(),
                context.read<CategoryRepository>(),
                initialFilter: LoadExpensesFilter(ofBudget: args.budgetId),
              ),
            ),
            BlocProvider(
              create: (BuildContext context) => CategoryListPageBloc(
                context.read<CategoryRepository>(),
                context.read<OfflineCategoryRepository>(),
              ),
            ),
            BlocProvider(
              create: (BuildContext context) => CategoryListPageBloc(
                context.read<CategoryRepository>(),
                context.read<OfflineCategoryRepository>(),
              ),
            ),
            BlocProvider(
              create: (context) => ExpenseEditPageBloc(
                context.read<ExpenseRepository>(),
                context.read<OfflineExpenseRepository>(),
                context.read<AuthBloc>(),
              ),
            ),
          ],
          child: ExpenseEditPage(item: item, isCreating: true),
        );
      });

  final Expense item;
  final bool isCreating;

  @override
  State<StatefulWidget> createState() => _ExpenseEditPageState();
}

class _ExpenseEditPageState extends State<ExpenseEditPage> {
  final _formKey = GlobalKey<FormState>();
  final FocusNode _nameEditorFocusNode = FocusNode();
  final _nameEditorController = TextEditingController();

  late var _amount = widget.item.amount;
  late var _name = widget.item.name;
  late DateTime _timestamp = widget.item.timestamp;
  late String? _categoryId = widget.item.categoryId;
  bool _autoName = true;
  String _budgetName = "";
  String _categoryName = "";
  bool _isSelectingCategory = false;

  bool _awaitingSave = false;

  @override
  void initState() {
    super.initState();
    _nameEditorController.text = _name;
    _nameEditorFocusNode.addListener(() {
      if (_nameEditorFocusNode.hasFocus) {
        setState(() {
          _autoName = false;
          _nameEditorController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _nameEditorController.value.text.length,
          );
        });
      }
    });
  }

  @override
  Widget build(context) =>
      BlocListener<ExpenseEditPageBloc, ExpenseEditPageBlocState>(
        listener: (context, state) {
          if (state is ExpenseEditSuccess) {
            if (_awaitingSave) setState(() => _awaitingSave = false);
            Navigator.pop(context);
          } else if (state is ExpenseEditFailed) {
            if (_awaitingSave) setState(() => _awaitingSave = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: state.error is ConnectionException
                    ? Text('Connection Failed')
                    : state.error is UnseenVersionException
                        ? Text('Desync error: sync first')
                        : Text('Unknown Error Occured'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            throw Exception("Unhandled type");
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: _awaitingSave
                ? const Text("Loading...")
                : widget.isCreating
                    ? Text("New expense")
                    : FittedBox(child: Text(widget.item.name)),
            actions: [
              TextButton(
                child: const Text("Save"),
                onPressed: !_awaitingSave
                    ? () {
                        final form = _formKey.currentState;
                        if (form != null && form.validate()) {
                          form.save();
                          if (widget.isCreating) {
                            context.read<ExpenseEditPageBloc>().add(
                                  CreateExpense(CreateExpenseInput(
                                    name: _name,
                                    budgetId: widget.item.budgetId,
                                    categoryId: widget.item.categoryId,
                                    amount: _amount,
                                    timestamp: _timestamp,
                                  )),
                                );
                          } else {
                            context.read<ExpenseEditPageBloc>().add(
                                  UpdateExpense(
                                    widget.item.id,
                                    UpdateExpenseInput.fromDiff(
                                      update: Expense.from(
                                        widget.item,
                                        name: _name,
                                        amount: _amount,
                                        timestamp: _timestamp,
                                      ),
                                      old: widget.item,
                                    ),
                                  ),
                                );
                          }
                          setState(() => _awaitingSave = true);
                        }
                      }
                    : null,
              ),
              TextButton(
                child: !_awaitingSave
                    ? const Text("Cancel")
                    : const CircularProgressIndicator(),
                onPressed:
                    !_awaitingSave ? () => Navigator.pop(context, false) : null,
              ),
            ],
          ),
          body: BlocConsumer<BudgetDetailsPageBloc, BudgetDetailsPageState>(
            listener: (context, current) {
              if (current is BudgetLoadSuccess) {
                setState(() {
                  _budgetName = current.item.name;
                });
                calcAutoName();
              }
            },
            builder: (context, budgetState) => budgetState is BudgetLoadSuccess
                ? BlocBuilder<ExpenseListPageBloc, ExpenseListPageBlocState>(
                    builder: (context, expensesState) => expensesState
                            is ExpensesLoadSuccess
                        ? BlocConsumer<CategoryListPageBloc,
                                CategoryListPageBlocState>(
                            listener: (context, current) {
                              if (current is CategoriesLoadSuccess &&
                                  _categoryId != null) {
                                setState(() {
                                  _categoryName =
                                      current.items[_categoryId!]!.name;
                                });
                                calcAutoName();
                              }
                            },
                            builder: (context, catListState) => catListState
                                    is CategoriesLoadSuccess
                                ? _form(context, catListState, expensesState,
                                    budgetState)
                                : catListState is CategoriesLoading
                                    ? const Center(
                                        child: Text("Loading categories..."))
                                    : throw Exception(
                                        "Unhandeled state: $catListState"))
                        : expensesState is ExpensesLoading
                            ? const Center(child: Text("Loading expenses..."))
                            : throw Exception(
                                "Unhandled state: $expensesState"))
                : budgetState is LoadingBudget
                    ? const Center(child: Text("Loading budget..."))
                    : budgetState is BudgetNotFound
                        ? const Center(child: Text("Error: budget not found."))
                        : throw Exception("Unhandled state: $budgetState"),
          ),
        ),
      );

  Widget _form(
    BuildContext context,
    CategoriesLoadSuccess catListState,
    ExpensesLoadSuccess expensesState,
    BudgetLoadSuccess budgetState,
  ) =>
      Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  /*  Row(
                    children: [
                      Checkbox(
                        value: _autoName,
                        onChanged: (b) {
                          setState(() => _autoName = b!);
                          calcAutoName();
                        },
                      ),
                      Text("Auto Name")
                    ],
                  ), */
                  TextFormField(
                    controller: _nameEditorController,
                    focusNode: _nameEditorFocusNode,
                    onSaved: (value) {
                      setState(() {
                        _name = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Name can't be empty";
                      }
                    },
                    decoration: InputDecoration(
                      // enabled: _autoName,
                      border: const OutlineInputBorder(),
                      hintText: "Name",
                      helperText: "Name",
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 12.0),
              child: MoneyFormEditor(
                initialValue: _amount,
                onSaved: (v) => setState(() => _amount = v!),
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(15)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Day: "),
                    Text(
                      humanReadableDayRelationName(
                        _timestamp,
                        DateTime.now(),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: _timestamp,
                          firstDate: DateTime.fromMillisecondsSinceEpoch(0),
                          lastDate: DateTime.now(),
                        );
                        if (selectedDate != null) {
                          setState(() => _timestamp = selectedDate);
                          calcAutoName();
                        }
                      },
                      icon: Icon(Icons.edit),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _catSelector(
                  context, catListState, expensesState, budgetState),
            ),
          ],
        ),
      );

  void calcAutoName() {
    if (_autoName) {
      _nameEditorController.text =
          "$_budgetName - $_categoryName - ${humanReadableDateTime(_timestamp)}";
    }
  }

  void _selectCategory(Category category) {
    setState(() {
      _categoryId = category.id;
      _categoryName = category.name;
      _isSelectingCategory = false;
    });
    calcAutoName();
  }

  Widget _catSelector(
    BuildContext context,
    CategoriesLoadSuccess itemsState,
    ExpensesLoadSuccess expensesState,
    BudgetLoadSuccess budgetState,
  ) {
    // var totalUsed = 0;
    final perCategoryUsed = <String, int>{};
    for (final expense in expensesState.items.values) {
      final expenseAmount = expense.amount.amount;
      // totalUsed += expenseAmount;
      perCategoryUsed.update(
        expense.categoryId,
        (value) => value + expenseAmount,
        ifAbsent: () => expenseAmount,
      );
    }
    return Column(
      children: [
        // the top bar
        ListTile(
          dense: true,
          title: const Text(
            "Category",
          ),
          trailing: TextButton(
            child: _isSelectingCategory
                ? const Text("Cancel")
                : const Text("Select"),
            onPressed: () {
              setState(() {
                _isSelectingCategory = !_isSelectingCategory;
              });
            },
          ),
        ),
        _isSelectingCategory
            ? _selecting(
                itemsState,
                budgetState,
                perCategoryUsed,
              )
            : _viewing(itemsState)
      ],
    );
  }

  Widget _selecting(
    CategoriesLoadSuccess itemsState,
    BudgetLoadSuccess budgetState,
    Map<String, int> perCategoryUsed,
  ) {
    // ignore: prefer_collection_literals
    Set<String> rootNodes = LinkedHashSet();

    final ancestryTree = CategoryRepositoryExt.calcAncestryTree(
      budgetState.item.categoryAllocations.keys.toSet()
        // allow adding to misc category no matter what
        ..add(context
            .read<PreferencesBloc>()
            .preferencesLoadSuccessState()
            .preferences
            .miscCategory),
      itemsState.items,
    );
    for (final node in ancestryTree.values.where((e) => e.parent == null)) {
      rootNodes.add(node.item);
    }

    return rootNodes.isNotEmpty
        ? ListView.builder(
            shrinkWrap: true,
            itemBuilder: (BuildContext context, int index) {
              final id = rootNodes.elementAt(index);
              return _catTree(
                context,
                budgetState,
                itemsState.items,
                ancestryTree,
                perCategoryUsed,
                id,
              );
            },
            itemCount: rootNodes.length,
          )
        : budgetState.item.categoryAllocations.isEmpty
            ? Center(child: const Text("No categories."))
            : throw Exception("error: parents are missing");
  }

  Widget _viewing(
    CategoriesLoadSuccess itemsState,
  ) {
    if (_categoryId != null) {
      final item = itemsState.items[_categoryId];
      if (item != null) {
        final parent =
            item.parentId != null ? itemsState.items[item.parentId] : null;
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListTile(
            title: Text(item.name),
            subtitle: Text(item.tags.map((e) => "#$e").toList().join(" ")),
            trailing: parent != null ? Text("Parent: ${parent.name}") : null,
          ),
        );
      } else {
        return Center(child: const Text("Error: selected item not found."));
      }
    } else {
      return const Center(child: Text("No category selected."));
    }
  }

  Widget _catTree(
    BuildContext context,
    BudgetLoadSuccess state,
    Map<String, Category> items,
    Map<String, TreeNode<String>> nodes,
    Map<String, int> perCategoryUsed,
    String id,
  ) {
    final item = items[id];
    final itemNode = nodes[id];
    if (item == null) return Text("Error: Category under id $id not found");
    if (itemNode == null) {
      return Text("Error: Category under id $id not found in ancestryGraph");
    }

    final allocatedAmount = state.item.categoryAllocations[id];
    final used = perCategoryUsed[id] ?? 0;

    return Column(
      children: [
        allocatedAmount != null
            ? ListTile(
                selected: _categoryId == id,
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
                      Text("${used / 100} / ${allocatedAmount / 100}"),
                      LinearProgressIndicator(
                        minHeight: 8,
                        value: used / allocatedAmount,
                        color: used > allocatedAmount ? Colors.red : null,
                      ),
                    ],
                  ),
                ),
                onTap: () => _selectCategory(item),
              )
            : ListTile(
                dense: true,
                title: Text(item.name),
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
                    items,
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
