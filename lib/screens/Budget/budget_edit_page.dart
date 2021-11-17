import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smuni/blocs/auth.dart';
import 'package:smuni/blocs/category_list_page.dart';
import 'package:smuni/blocs/edit_page/budget_edit_page.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni/widgets/category_selector.dart';
import 'package:smuni/widgets/money_editor.dart';
import 'package:smuni/widgets/widgets.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

import '../../constants.dart';

class BudgetEditPage extends StatefulWidget {
  static const String routeName = "/budgetEdit";

  final Budget item;
  final bool isCreating;

  const BudgetEditPage({
    Key? key,
    required this.item,
    required this.isCreating,
  }) : super(key: key);

  static Route route(Budget item) => MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (context) => BlocProvider(
          create: (context) => BudgetEditPageBloc(
            context.read<BudgetRepository>(),
            context.read<OfflineBudgetRepository>(),
            context.read<AuthBloc>(),
          ),
          child: BlocProvider(
            create: (context) => CategoryListPageBloc(
              context.read<CategoryRepository>(),
              context.read<OfflineCategoryRepository>(),
            ),
            child: BudgetEditPage(
              item: item,
              isCreating: false,
            ),
          ),
        ),
      );

  static Route routeNew() => MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) {
        final now = DateTime.now();
        final range = DateRange.monthRange(now);
        final item = Budget(
          id: "id-${now.microsecondsSinceEpoch}",
          createdAt: now,
          updatedAt: now,
          name: "",
          allocatedAmount: MonetaryAmount(currency: "ETB", amount: 0),
          startTime: range.start,
          endTime: range.end,
          frequency: OneTime(),
          categoryAllocations: {},
        );
        return BlocProvider(
          create: (context) => BudgetEditPageBloc(
            context.read<BudgetRepository>(),
            context.read<OfflineBudgetRepository>(),
            context.read<AuthBloc>(),
          ),
          child: BlocProvider(
            create: (context) => CategoryListPageBloc(
              context.read<CategoryRepository>(),
              context.read<OfflineCategoryRepository>(),
            ),
            child: BudgetEditPage(
              item: item,
              isCreating: true,
            ),
          ),
        );
      });

  @override
  State<StatefulWidget> createState() => _BudgetEditPageState();
}

class _BudgetEditPageState extends State<BudgetEditPage> {
  final _formKey = GlobalKey<FormState>();

  late var _amount = widget.item.allocatedAmount;
  late var _name = widget.item.name;
  late var _startTime = widget.item.startTime;
  late var _endTime = widget.item.endTime;
  late var _isOneTime = widget.item.frequency is OneTime;
  late var _frequency = widget.item.frequency;
  late final _categoryAllocations = <String, int>{
    ...widget.item.categoryAllocations
  };

  String? _selectedCategory;
  bool _awaitingSave = false;

  @override
  Widget build(context) =>
      BlocListener<BudgetEditPageBloc, BudgetEditPageBlocState>(
        listener: (context, state) {
          if (state is BudgetEditSuccess) {
            if (_awaitingSave) setState(() => {_awaitingSave = false});
            Navigator.pop(context);
          } else if (state is BudgetEditFailed) {
            if (_awaitingSave) setState(() => {_awaitingSave = false});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: state.error is ConnectionException
                    ? Text('Connection Failed')
                    : state.error is UnseenVersionException
                        ? Text(
                            'Desync error: sync first',
                          )
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
            backgroundColor: semuni50,
            foregroundColor: Colors.black,
            shadowColor: Colors.transparent,
            title: _awaitingSave
                ? const Text("Loading...")
                : widget.isCreating
                    ? const Text("New budget")
                    : FittedBox(child: Text(widget.item.name)),
            actions: !_awaitingSave
                ? [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4.0, vertical: 8),
                      child: TextButton(
                        child: const Text("Save"),
                        onPressed: () {
                          final allocated = _categoryAllocations.isNotEmpty
                              ? _categoryAllocations.values
                                  .reduce((a, b) => a + b)
                              : 0;
                          final remaining = _amount.amount - allocated;

                          final form = _formKey.currentState;
                          if (remaining != 0) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(remaining > 0
                                  ? "Unallocated amount remains."
                                  : "Allocation over budget."),
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                          if (form != null &&
                              form.validate() &&
                              remaining == 0) {
                            form.save();
                            if (widget.isCreating) {
                              context.read<BudgetEditPageBloc>().add(
                                    CreateBudget(CreateBudgetInput(
                                      name: _name,
                                      startTime: _startTime,
                                      endTime: _endTime,
                                      frequency: _frequency,
                                      allocatedAmount: _amount,
                                      categoryAllocations: _categoryAllocations,
                                    )),
                                  );
                            } else {
                              context.read<BudgetEditPageBloc>().add(
                                    UpdateBudget(
                                        widget.item.id,
                                        UpdateBudgetInput.fromDiff(
                                          update: Budget.from(
                                            widget.item,
                                            name: _name,
                                            allocatedAmount: _amount,
                                            frequency: _frequency,
                                            startTime: _startTime,
                                            endTime: _endTime,
                                            categoryAllocations:
                                                _categoryAllocations,
                                          ),
                                          old: widget.item,
                                        )),
                                  );
                            }
                            setState(() => _awaitingSave = true);
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4.0, vertical: 8),
                      child: TextButton(
                        child: const Text("Cancel"),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                    ),
                  ]
                : null,
          ),
          body: Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: TextFormField(
                    initialValue: _name,
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
                      border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12))),
                      hintText: "Name",
                      helperText: "Name",
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8.0, 0, 8),
                  child: MoneyFormEditor(
                    initialValue: _amount,
                    onChanged: (v) => setState(() => _amount = v!),
                  ),
                ),
                _isOneTime
                    ? _oneTimeDateRangeSelctor(context)
                    : _recurringDateRangeSelctor(context),
                CheckboxListTile(
                  dense: false,
                  title: Text(
                    'One Time',
                    textScaleFactor: 1.3,
                  ),
                  value: _isOneTime,
                  onChanged: (value) {
                    setState(() {
                      _isOneTime = value!;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  secondary: _isOneTime
                      ? Icon(Icons.looks_one, color: semuni500)
                      : Icon(
                          Icons.repeat,
                          color: semuni500,
                        ),
                ),
                Builder(builder: (context) {
                  final allocated = _categoryAllocations.isNotEmpty
                      ? _categoryAllocations.values.reduce((a, b) => a + b)
                      : 0;
                  final remaining = _amount.amount - allocated;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Allocated: ${_amount.currency} ${allocated / 100}",
                              textScaleFactor: 1.2,
                            ),
                            Text(
                              "Remaining: ${_amount.currency} ${(remaining) / 100}",
                              textScaleFactor: 1.2,
                              style: remaining == 0
                                  ? TextStyle(color: Colors.green)
                                  : TextStyle(color: Colors.amber[800]),
                            )
                          ],
                        ),
                      ),
                      Text(
                        "Allocated categories",
                        textScaleFactor: 1.3,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (remaining != 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              remaining > 0
                                  ? "Unallocated amount remains."
                                  : "Allocation over budget.",
                              style: TextStyle(color: Colors.amber[800]),
                            ),
                            IconButton(
                                onPressed: () => showDialog(
                                    context: context,
                                    builder: (context) => SimpleDialog(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                  "Zero-based budgeting (ZBB) is a method of budgeting in which all categories must be justified for each new period."),
                                            )
                                          ],
                                        )),
                                icon: Icon(Icons.info_outline))
                          ],
                        ),
                      if (remaining > 0)
                        TextButton(
                          onPressed: _amount.amount > 0
                              ? () async {
                                  final allocation =
                                      await _allocateCategoryModal();
                                  if (allocation != null) {
                                    setState(() =>
                                        _categoryAllocations[allocation.a] =
                                            allocation.b.amount);
                                  }
                                }
                              : null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add),
                              Text("Allocate Category"),
                            ],
                          ),
                        ),
                    ],
                  );
                }),
                Expanded(
                  child: BlocBuilder<CategoryListPageBloc,
                      CategoryListPageBlocState>(
                    builder: (context, catListState) {
                      if (catListState is CategoriesLoadSuccess) {
                        // ignore: prefer_collection_literals
                        Set<String> rootNodes = LinkedHashSet();

                        // FIXME: move this calculation elsewhere
                        final ancestryTree =
                            CategoryRepositoryExt.calcAncestryTree(
                          _categoryAllocations.keys.toSet(),
                          catListState.items,
                        );
                        for (final node in ancestryTree.values
                            .where((e) => e.parent == null)) {
                          rootNodes.add(node.item);
                        }
                        return rootNodes.isNotEmpty
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: ListView.builder(
                                  itemCount: rootNodes.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final item = rootNodes.elementAt(index);
                                    return _catTree(
                                      context,
                                      catListState.items,
                                      ancestryTree,
                                      item,
                                    );
                                  },
                                ),
                              )
                            : _categoryAllocations.isEmpty
                                ? Center(child: const Text("No categories."))
                                : throw Exception("parents are missing");
                      }
                      return Center(
                          child: CircularProgressIndicator.adaptive());
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _recurringDateRangeSelctor(BuildContext context) {
    final now = DateTime.now();
    final weekRange = DateRange.weekRange(now);
    final twoWeekRange = DateRange(
      startTime: weekRange.startTime,
      endTime: weekRange.endTime + Duration(days: 7).inMilliseconds,
    );
    return SimpleDateRangeFormEditor(
      initialValue: DateRange.usingDates(start: _startTime, end: _endTime),
      rangesToShow: [
        DateRangeFilter("Every Day", DateRange.dayRange(now), FilterLevel.day),
        DateRangeFilter("Every Week", weekRange, FilterLevel.week),
        DateRangeFilter("Every Two Weeks", twoWeekRange, FilterLevel.week),
        DateRangeFilter(
          "Every Month",
          DateRange.monthRange(now),
          FilterLevel.month,
        ),
      ],
      validator: (range) {
        if (range == null) return "Day range not selected";
      },
      onSaved: (range) => setState(() {
        _startTime = range!.start;
        _endTime = range.end;
        _frequency = Recurring(range.duration.inSeconds);
      }),
    );
  }

  Widget _oneTimeDateRangeSelctor(BuildContext context) {
    final now = DateTime.now();
    final weekRange = DateRange.weekRange(now);
    final next7Days = DateRange.usingDates(
      start: now,
      end: now.add(Duration(days: 7)),
    );
    final next14Days = DateRange.usingDates(
      start: now,
      end: now.add(Duration(days: 14)),
    );
    final next30Days = DateRange.usingDates(
      start: now,
      end: now.add(Duration(days: 30)),
    );
    return SimpleDateRangeFormEditor(
      initialValue: DateRange.usingDates(start: _startTime, end: _endTime),
      rangesToShow: [
        DateRangeFilter("Today", DateRange.dayRange(now), FilterLevel.day),
        DateRangeFilter("This Week", weekRange, FilterLevel.week),
        DateRangeFilter("Next 7 Days", next7Days, FilterLevel.week),
        DateRangeFilter("Next 14 Days", next14Days, FilterLevel.week),
        DateRangeFilter(
          "This Month",
          DateRange.monthRange(now),
          FilterLevel.month,
        ),
        DateRangeFilter(
          "Next 30 Days",
          next30Days,
          FilterLevel.month,
        ),
      ],
      validator: (range) {
        if (range == null) return "Day range not selected";
      },
      onSaved: (range) => setState(() {
        _startTime = range!.start;
        _endTime = range.end;
        _frequency = OneTime();
      }),
    );
  }

  Widget _catTree(
    BuildContext context,
    Map<String, Category> items,
    Map<String, TreeNode<String>> nodes,
    String id,
  ) {
    final item = items[id];
    final itemNode = nodes[id];
    if (item == null) return Text("Error: Category under id $id not found");
    if (itemNode == null) {
      return Text("Error: Category under id $id not found in ancestryGraph");
    }

    final allocatedAmount = _categoryAllocations[id];
    return Column(
      children: [
        allocatedAmount != null
            ? ListTile(
                title: Text(item.name),
                //title: Text('hereeee'),
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
                    children: [
                      Text("${allocatedAmount / 100}"),
                      if (_amount.amount != 0)
                        LinearProgressIndicator(
                          value: allocatedAmount / _amount.amount,
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
              )
            : Row(
                children: [
                  Text(item.name),
                ],
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
                  TextButton.icon(
                    onPressed: () async {
                      final allocation = await _allocateCategoryModal(id);
                      if (allocation != null) {
                        if (allocation.a != id) {
                          final confirm = await showDialog<bool?>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Confirm Category Swap"),
                              content: Text(
                                "Are you sure you want to replace category ${item.name} with ${items[allocation.a]!.name}?"
                                "\nExpenses attached to the initial category, ${item.name}, under this budget will be left intact",
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text("Swap"),
                                ),
                              ],
                            ),
                          );
                          if (confirm == null || !confirm) return;
                        }
                        setState(() {
                          _categoryAllocations.remove(id);
                          _categoryAllocations[allocation.a] =
                              allocation.b.amount;
                          _selectedCategory = null;
                        });
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text("Reallocate"),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool?>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("Confirm Deallocation"),
                          content: Text(
                              "Are you sure you want to remove category ${item.name} from the budget?"
                              "\nExpenses attached to the Category under this budget will be left intact"),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text("Deallocate"),
                            ),
                          ],
                        ),
                      );
                      if (confirm != null && confirm) {
                        setState(() {
                          _categoryAllocations.remove(id);
                          _selectedCategory = null;
                        });
                      }
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text("Deallocated"),
                  ),
                ]),
          ),
        if (itemNode.children.isNotEmpty)
          Padding(
            padding:
                EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.05),
            child: Column(
              children: [
                ...itemNode.children.map(
                  (e) => _catTree(context, items, nodes, e),
                ),
              ],
            ),
          )
      ],
    );
  }

  Future<Pair<String, MonetaryAmount>?> _allocateCategoryModal([
    String? forCategoryId,
  ]) async {
    var allocated = _categoryAllocations.isNotEmpty
        ? _categoryAllocations.values.reduce((a, b) => a + b)
        : 0;
    var unused = _amount.amount - allocated;

    final selectorKey = GlobalKey<FormFieldState<String>>();

    String? categoryId = forCategoryId;
    final disabledItems = _categoryAllocations.keys.toSet();
    MonetaryAmount categoryAmount = MonetaryAmount(currency: "ETB", amount: 0);

    if (categoryId != null) {
      final amount = _categoryAllocations[categoryId];
      if (amount != null) {
        categoryAmount = MonetaryAmount(
          currency: "ETB",
          amount: amount,
        );
        allocated -= amount;
        unused += amount;
      }
      disabledItems.remove(categoryId);
    }
    return showModalBottomSheet<Pair<String, MonetaryAmount>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Column(
          children: [
            ElevatedButton(
              onPressed: categoryId != null
                  ? () {
                      final selector = selectorKey.currentState;
                      if (selector != null && selector.validate()) {
                        selector.save();
                        Navigator.pop(
                            context, Pair(categoryId!, categoryAmount));
                      }
                    }
                  : null,
              child: const Text("Allocate Category"),
            ),
            // TODO: slider
            /* Slider(
              activeColor:
                  categoryAmount.amount > _amount.amount ? Colors.red : null,
              value: (unused > 0 ? (categoryAmount.amount / unused) : 0)
                  .clamp(0, 1)
                  .toDouble(),
              onChanged: (v) {
                setState(
                  () => categoryAmount = MonetaryAmount(
                      currency: categoryAmount.currency,
                      amount: (v * unused).truncate()),
                );
              },
            ), */
            MoneyFormEditor(
              initialValue: categoryAmount,
              onChanged: (v) => setState(() => categoryAmount = v!),
              validator: (v) {
                if (v == null || v.amount > unused) {
                  return "Over budget allocation";
                }
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            Expanded(
              child: BlocProvider(
                create: (context) => CategoryListPageBloc(
                  context.read<CategoryRepository>(),
                  context.read<OfflineCategoryRepository>(),
                ),
                child: BlocBuilder<CategoryListPageBloc,
                    CategoryListPageBlocState>(
                  builder: (context, catListState) => catListState
                          is CategoriesLoadSuccess
                      ? CategoryFormSelector(
                          key: selectorKey,
                          disabledItems: _categoryAllocations.keys.toSet()
                            ..remove(categoryId),
                          initialValue: categoryId,
                          isSelecting: categoryId == null,
                          onChanged: (value) =>
                              setState(() => categoryId = value!),
                          validator: (value) {
                            if (value == null) {
                              return "Category not selected";
                            } else if (catListState.items[value]!.isArchived) {
                              return "Category is archived.";
                            }
                          },
                        )
                      : const CircularProgressIndicator(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
