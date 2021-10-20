import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smuni/blocs/category_list_page.dart';
import 'package:smuni/blocs/edit_page/budget_edit_page.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni/widgets/category_selector.dart';
import 'package:smuni/widgets/money_editor.dart';
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
          ),
          child: BlocProvider(
            create: (context) =>
                CategoryListPageBloc(context.read<CategoryRepository>()),
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
          create: (context) =>
              BudgetEditPageBloc(context.read<BudgetRepository>()),
          child: BlocProvider(
            create: (context) =>
                CategoryListPageBloc(context.read<CategoryRepository>()),
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
  late final _categoryAllocation = {...widget.item.categoryAllocations};

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
                    : Text('Unknown Error Occured'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 1),
              ),
            );
          }
          throw Exception("Unhandled type");
        },
        child: Scaffold(
          appBar: AppBar(
            title: _awaitingSave
                ? const Text("Loading...")
                : widget.isCreating
                    ? const Text("Create budget")
                    : Text("Editing budget: ${widget.item.name}"),
            actions: !_awaitingSave
                ? [
                    ElevatedButton(
                      child: const Text("Save"),
                      onPressed: () {
                        final allocated = _categoryAllocation.isNotEmpty
                            ? _categoryAllocation.values.reduce((a, b) => a + b)
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
                        if (form != null && form.validate() && remaining == 0) {
                          form.save();
                          if (widget.isCreating) {
                            context.read<BudgetEditPageBloc>().add(
                                  CreateBudget(CreateBudgetInput(
                                    name: _name,
                                    startTime: _startTime,
                                    endTime: _endTime,
                                    frequency: _frequency,
                                    allocatedAmount: _amount,
                                    categoryAllocations: _categoryAllocation,
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
                                          categoryAllocation:
                                              _categoryAllocation,
                                        ),
                                        old: widget.item,
                                      )),
                                );
                          }
                          setState(() => _awaitingSave = true);
                        }
                      },
                    ),
                    ElevatedButton(
                      child: const Text("Cancel"),
                      onPressed: () => Navigator.pop(context, false),
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
                  final allocated = _categoryAllocation.isNotEmpty
                      ? _categoryAllocation.values.reduce((a, b) => a + b)
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
                                  : TextStyle(color: Colors.red),
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
                              style: TextStyle(color: Colors.red),
                            ),
                            IconButton(
                                onPressed: () => showDialog(
                                    context: context,
                                    builder: (context) => SimpleDialog(
                                          children: [
                                            Text(
                                                "TODO: explain zero based budgeting")
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
                                        _categoryAllocation[allocation.a] =
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
                        Set<String> nodes = LinkedHashSet();
                        // ignore: prefer_collection_literals
                        Set<String> rootNodes = LinkedHashSet();
                        for (final id in _categoryAllocation.keys) {
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
                            ? ListView.builder(
                                itemCount: rootNodes.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final item = rootNodes.elementAt(index);
                                  return _catTree(
                                      context, catListState, nodes, item);
                                },
                              )
                            : _categoryAllocation.isEmpty
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
        endTime: weekRange.endTime + Duration(days: 7).inMilliseconds);
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
      onSaved: (range) {
        setState(() {
          _startTime = range!.start;
          _endTime = range.end;
          _frequency = Recurring(range.duration.inSeconds);
        });
      },
      validator: (range) {
        if (range == null) return "Name can't be empty";
      },
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
          "This Month Month",
          DateRange.monthRange(now),
          FilterLevel.month,
        ),
        DateRangeFilter(
          "Next 30 Days",
          next30Days,
          FilterLevel.month,
        ),
      ],
      onSaved: (range) {
        setState(() {
          _startTime = range!.start;
          _endTime = range.end;
        });
      },
    );
  }

  Widget _catTree(
    BuildContext context,
    CategoriesLoadSuccess catListState,
    Set<String> nodesToShow,
    String id,
  ) {
    final item = catListState.items[id];
    final itemNode = catListState.ancestryGraph[id];
    if (item == null) return Text("Error: Category under id $id not found");
    if (itemNode == null) {
      return Text("Error: Category under id $id not found in ancestryGraph");
    }

    final children = itemNode.children.where((e) => nodesToShow.contains(e));

    final allocatedAmount = _categoryAllocation[id];
    return Column(
      children: [
        allocatedAmount != null
            ? Builder(builder: (context) {
                return ListTile(
                  title: Text(item.name),
                  subtitle:
                      Text(item.tags.map((e) => "#$e").toList().join(" ")),
                  trailing: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: Column(
                      children: [
                        Text("${allocatedAmount / 100}"),
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
                );
              })
            : Row(
                children: [
                  Text(item.name),
                ],
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
                        title: const Text("Deallocated"),
                        leading: Icon(Icons.delete),
                        onTap: () => setState(() {
                          _categoryAllocation.remove(id);
                          _selectedCategory = null;
                        }),
                      ),
                    ]),
                  ),
                ...itemNode.children.map(
                  (e) => _catTree(
                    context,
                    catListState,
                    nodesToShow,
                    e,
                  ),
                ),
              ],
            ),
          )
      ],
    );
  }

  Future<Pair<String, MonetaryAmount>?> _allocateCategoryModal() async {
    final allocated = _categoryAllocation.isNotEmpty
        ? _categoryAllocation.values.reduce((a, b) => a + b)
        : 0;
    final unused = _amount.amount - allocated;

    final selectorKey = GlobalKey<FormFieldState<String>>();
    var categoryId = "";
    MonetaryAmount categoryAmount = MonetaryAmount(currency: "ETB", amount: 0);
    return showModalBottomSheet<Pair<String, MonetaryAmount>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (builder, setState) => Column(children: [
            ElevatedButton(
              onPressed: categoryId.isNotEmpty
                  ? () {
                      final selector = selectorKey.currentState;
                      if (selector != null && selector.validate()) {
                        selector.save();
                        Navigator.pop(
                            context, Pair(categoryId, categoryAmount));
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
            BlocProvider(
              create: (context) =>
                  CategoryListPageBloc(context.read<CategoryRepository>()),
              child: Expanded(
                child: CategoryFormSelector(
                  key: selectorKey,
                  disabledItems: _categoryAllocation.keys.toSet(),
                  isSelecting: true,
                  onChanged: (value) {
                    setState(() => categoryId = value!);
                  },
                  validator: (value) {
                    if (value == null) {
                      return "Category not selected";
                    }
                  },
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

class SimpleDateRangeFormEditor extends FormField<DateRange> {
  SimpleDateRangeFormEditor({
    Key? key,
    Widget? caption,
    DateRange? initialValue,
    FormFieldSetter<DateRange>? onSaved,
    void Function(DateRange?)? onChanged,
    FormFieldValidator<DateRange>? validator,
    // AutovalidateMode? autovalidateMode,
    // bool? enabled,
    String? restorationId,
    List<DateRangeFilter>? rangesToShow,
  }) : super(
          key: key,
          initialValue: initialValue,
          validator: validator,
          onSaved: onSaved,
          restorationId: restorationId,
          builder: (state) => SimpleDateRangeEditor(
            caption: state.errorText != null
                ? Text(state.errorText!, style: TextStyle(color: Colors.red))
                : caption,
            initialValue: state.value,
            rangesToShow: rangesToShow,
            onChanged: (value) {
              state.didChange(value);
              onChanged?.call(value);
            },
          ),
        );
}

class SimpleDateRangeEditor extends StatefulWidget {
  // late final Frequency initialFrequency;
  late final DateRange initialValue;
  late final List<DateRangeFilter> rangesToShow;
  final void Function(DateRange)? onChanged;
  final Widget? caption;
  SimpleDateRangeEditor({
    Key? key,
    DateRange? initialValue,
    List<DateRangeFilter>? rangesToShow,
    this.onChanged,
    this.caption,
    // this.initialFrequency = const OneTime(),
  })  : initialValue = initialValue ?? DateRange.monthRange(DateTime.now()),
        rangesToShow = rangesToShow ?? [],
        super(key: key);

  @override
  _SimpleDateRangeEditorState createState() => _SimpleDateRangeEditorState();
}

class _SimpleDateRangeEditorState extends State<SimpleDateRangeEditor> {
  // late bool _isOneTime = widget.initialFrequency is OneTime;
  late DateRange _range = widget.initialValue;
  late DateRangeFilter custom =
      DateRangeFilter("Custom", widget.initialValue, FilterLevel.custom);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.caption != null) widget.caption!,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(
                width: 16,
              ),
              ChoiceChip(
                selected: _range == custom.range,
                onSelected: (_) async {
                  final range = await showDateRangePicker(
                    context: context,
                    helpText: "Custom Budget Day Range",
                    fieldStartLabelText: "Start Date",
                    fieldEndLabelText: "End Date",
                    initialEntryMode: DatePickerEntryMode.input,
                    initialDateRange: custom.range.toFlutter(),
                    firstDate: DateTime.fromMillisecondsSinceEpoch(0),
                    lastDate:
                        DateTime.fromMillisecondsSinceEpoch(8640000000000000),
                    // TODO: localization
                  );
                  if (range != null) {
                    setState(() {
                      custom = DateRangeFilter(
                        "Custom",
                        DateRange.fromFlutter(range),
                        FilterLevel.custom,
                      );
                      _range = DateRange.fromFlutter(range);
                    });
                  }
                },
                label: Row(children: const [
                  Icon(Icons.arrow_downward),
                  Text("Custom")
                ]),
              ),
              ...widget.rangesToShow.map(
                (e) => Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: ChoiceChip(
                    selected: _range == e.range,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _range = e.range;
                        });
                      }
                    },
                    label: Text(e.name),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /*  Widget selectorTextField() => TextFormField(
        controller: dateController,
        readOnly: true,
        autofocus: true,
        decoration: InputDecoration(
            hintText: fieldName,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffix: IconButton(
              autofocus: true,
              icon: Icon(Icons.calendar_today),
              onPressed: () async {
                if (fieldName == 'Start Date') {
                  DateTime? pickedDay = await showDatePicker(
                      context: context,
                      helpText: helpText,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(9999));
                  _startDate = pickedDay;
                  if (pickedDay != null)
                    dateController.text =
                        '${pickedDay.month.toString()}/${pickedDay.day.toString()}/${pickedDay.year.toString()}';
                } else if (fieldName == 'End Date') {
                  if (_startDate == null) {
                    var snackBar =
                        SnackBar(content: Text("Choose start day first"));
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    return;
                  }
                  DateTime? pickedDay = await showDatePicker(
                      context: context,
                      helpText: helpText,
                      initialDate: _startDate!,
                      firstDate: _startDate!,
                      lastDate: DateTime(9999));
                  _endDate = pickedDay;
                  if (pickedDay != null)
                    dateController.text =
                        '${pickedDay.month.toString()}/${pickedDay.day.toString()}/${pickedDay.year.toString()}';
                }
              },
            )),
      ); */
}
