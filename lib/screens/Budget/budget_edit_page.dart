import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smuni/blocs/budget_edit_page.dart';
import 'package:smuni/blocs/category_list_page.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni/widgets/category_selector.dart';
import 'package:smuni/widgets/money_editor.dart';

class BudgetEditPage extends StatefulWidget {
  static const String routeName = "budgetEdit";

  const BudgetEditPage({Key? key}) : super(key: key);

  static Route route(String id) => MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (context) => BlocProvider(
          create: (context) =>
              BudgetEditPageBloc(context.read<BudgetRepository>(), id),
          child: BlocProvider(
            create: (context) =>
                CategoryListPageBloc(context.read<CategoryRepository>()),
            child: BudgetEditPage(),
          ),
        ),
      );

  static Route routeNew() => MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) {
        final now = DateTime.now();
        final range = DateRange.monthRange(now);
        final item = Budget(
          id: "new-id",
          createdAt: now,
          updatedAt: now,
          name: "",
          allocatedAmount: MonetaryAmount(currency: "ETB", amount: 0),
          startTime: range.start,
          endTime: range.end,
          frequency: OneTime(),
          categoryAllocation: {},
        );
        return BlocProvider(
          create: (context) => BudgetEditPageBloc.modified(
              context.read<BudgetRepository>(), item),
          child: BlocProvider(
            create: (context) =>
                CategoryListPageBloc(context.read<CategoryRepository>()),
            child: BudgetEditPage(),
          ),
        );
      });

  @override
  State<StatefulWidget> createState() => _BudgetEditPageState();
}

class _BudgetEditPageState extends State<BudgetEditPage> {
  final _formKey = GlobalKey<FormState>();

  MonetaryAmount _amount = MonetaryAmount(currency: "ETB", amount: 0);
  String _name = "";
  DateTime _startTime = DateTime.utc(0);
  DateTime _endTime = DateTime.utc(0);
  bool _isOneTime = true;
  Frequency _frequency = OneTime();
  Map<String, int> _categoryAllocation = {};
  String? _selectedCategory;

  String _categoryAllocationError = "";

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<BudgetEditPageBloc, BudgetEditPageBlocState>(
        listener: (context, state) {
          if (state is UnmodifiedEditState)
            setState(() => _isOneTime = state.unmodified.frequency is OneTime);
        },
        builder: (context, state) {
          if (state is UnmodifiedEditState) {
            return _form(context, state);
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

  Widget _form(BuildContext context, UnmodifiedEditState state) => Scaffold(
        appBar: AppBar(
          title: Text("Editing budget: ${state.unmodified.name}"),
          actions: [
            ElevatedButton(
              onPressed: () {
                final form = this._formKey.currentState;
                if (form != null && form.validate()) {
                  form.save();
                  final modified = Budget.from(
                    state.unmodified,
                    name: _name,
                    allocatedAmount: _amount,
                    frequency: _frequency,
                    startTime: _startTime,
                    endTime: _endTime,
                    categoryAllocation: _categoryAllocation,
                  );
                  context.read<BudgetEditPageBloc>()
                    ..add(
                      ModifyItem(modified),
                    )
                    ..add(SaveChanges());
                  /* Navigator.popAndPushNamed(
                          context,
                          CategoryDetailsPage.routeName,
                          arguments: bloc.state.unmodified.id,
                        ); 
                        */
                  Navigator.pop(context, true);
                }
              },
              child: const Text("Save"),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<BudgetEditPageBloc>().add(DiscardChanges());
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: state.unmodified.name,
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
                  border: const OutlineInputBorder(),
                  hintText: "Name",
                  helperText: "Name",
                ),
              ),
              MoneyFormEditor(
                initialValue: state.unmodified.allocatedAmount,
                onChanged: (v) => setState(() => _amount = v!),
              ),
              /* Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 8, 0),
                child: FrequencyFormEditor(
                  initialValue: state.unmodified.frequency,
                  onChanged: (value) => setState(() => _frequency = value!),
                ),
              ), */
              _isOneTime
                  ? _oneTimeDateRangeSelctor(context, state)
                  : _recurringDateRangeSelctor(context, state),
              CheckboxListTile(
                dense: true,
                title: Text('One Time'),
                value: _isOneTime,
                onChanged: (value) {
                  setState(() {
                    _isOneTime = value!;
                  });
                },
              ),
              Builder(builder: (context) {
                final allocated = _categoryAllocation.isNotEmpty
                    ? _categoryAllocation.values.reduce((a, b) => a + b)
                    : 0;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text("Allocated: ${_amount.currency} ${allocated / 100}"),
                    Text(
                      "Remaining: ${_amount.currency} ${(_amount.amount - allocated) / 100}",
                    )
                  ],
                );
              }),
              TextButton(
                onPressed: _amount.amount > 0
                    ? () async {
                        final allocation = await _allocateCategoryModal();
                        if (allocation != null)
                          setState(() => _categoryAllocation[allocation.a] =
                              allocation.b.amount);
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
              Expanded(
                child: BlocBuilder<CategoryListPageBloc,
                    CategoryListPageBlocState>(
                  builder: (context, catListState) {
                    if (catListState is CategoriesLoadSuccess) {
                      Set<String> nodes = new LinkedHashSet();
                      Set<String> rootNodes = new LinkedHashSet();
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
                    return Center(child: CircularProgressIndicator.adaptive());
                  },
                ),
              ),
            ],
          ),
        ),
      );

  Widget _recurringDateRangeSelctor(
    BuildContext context,
    UnmodifiedEditState state,
  ) {
    final now = DateTime.now();
    final weekRange = DateRange.weekRange(now);
    final twoWeekRange = DateRange(
        startTime: weekRange.startTime,
        endTime: weekRange.endTime + Duration(days: 7).inMilliseconds);
    return SimpleDateRangeFormEditor(
      initialValue: DateRange.usingDates(
        start: state.unmodified.startTime,
        end: state.unmodified.endTime,
      ),
      rangesToShow: [
        DateRangeFilter("Every Day", DateRange.dayRange(now), FilterLevel.Day),
        DateRangeFilter("Every Week", weekRange, FilterLevel.Week),
        DateRangeFilter("Every Two Weeks", twoWeekRange, FilterLevel.Week),
        DateRangeFilter(
          "Every Month",
          DateRange.monthRange(now),
          FilterLevel.Month,
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
      // initialFrequency: state.unmodified.frequency,
    );
  }

  Widget _oneTimeDateRangeSelctor(
    BuildContext context,
    UnmodifiedEditState state,
  ) {
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
      initialValue: DateRange.usingDates(
        start: state.unmodified.startTime,
        end: state.unmodified.endTime,
      ),
      rangesToShow: [
        DateRangeFilter("Today", DateRange.dayRange(now), FilterLevel.Day),
        DateRangeFilter("This Week", weekRange, FilterLevel.Week),
        DateRangeFilter("Next 7 Days", next7Days, FilterLevel.Week),
        DateRangeFilter("Next 14 Days", next14Days, FilterLevel.Week),
        DateRangeFilter(
          "This Month Month",
          DateRange.monthRange(now),
          FilterLevel.Month,
        ),
        DateRangeFilter(
          "Next 30 Days",
          next30Days,
          FilterLevel.Month,
        ),
      ],
      onSaved: (range) {
        setState(() {
          _startTime = range!.start;
          _endTime = range.end;
        });
      },
      // initialFrequency: state.unmodified.frequency,
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
    if (itemNode == null)
      return Text("Error: Category under id $id not found in ancestryGraph");

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
                        Text(
                            "${allocatedAmount / 100} / ${_amount.amount / 100}"),
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
                        onTap: () =>
                            setState(() => _categoryAllocation.remove(id)),
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
            const Text("Allocate Category"),
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
              onSaved: (v) => setState(() => categoryAmount = v!),
              validator: (v) {
                if (v == null || v.amount > unused)
                  return "Over budget allocation";
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
              child: const Text("Save"),
            )
          ]),
        );
      },
    );
  }
}

/* class FrequencyFormEditor extends FormField<Frequency> {
  FrequencyFormEditor({
    Key? key,
    Widget? caption,
    Frequency? initialValue,
    FormFieldSetter<Frequency>? onSaved,
    void Function(Frequency?)? onChanged,
    FormFieldValidator<Frequency>? validator,
    // AutovalidateMode? autovalidateMode,
    // bool? enabled,
    String? restorationId,
  }) : super(
          key: key,
          initialValue: initialValue,
          validator: validator,
          onSaved: onSaved,
          restorationId: restorationId,
          builder: (state) => FrequencyEditor(
            caption: state.errorText != null
                ? Text(state.errorText!, style: TextStyle(color: Colors.red))
                : caption != null
                    ? caption
                    : null,
            initialValue: state.value,
            onChanged: (value) {
              state.didChange(value);
              onChanged?.call(value);
            },
          ),
        );
}

class FrequencyEditor extends StatefulWidget {
  final Widget? caption;
  final Frequency initialValue;
  final void Function(Frequency)? onChanged;
  const FrequencyEditor(
      {Key? key, Frequency? initialValue, this.onChanged, this.caption})
      : this.initialValue = initialValue ?? const OneTime(),
        super(key: key);

  @override
  _FrequencyEditorState createState() => _FrequencyEditorState();
}

class _FrequencyEditorState extends State<FrequencyEditor> {
  late bool _isOneTime = widget.initialValue is OneTime;
  late int _recurrenceIntervals =
      (widget.initialValue as Recurring?)?.recurringIntervalSecs ?? 0;
  @override
  Widget build(BuildContext context) => Column(
        children: [
          widget.caption ?? const Text("Frequency"),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Checkbox(
                value: _isOneTime,
                onChanged: (value) {
                  setState(() {
                    _isOneTime = value!;
                  });
                  widget.onChanged?.call(
                    value! ? const OneTime() : Recurring(_recurrenceIntervals),
                  );
                },
              ),
              Text('One Time'),
              if (!_isOneTime)
                DropdownButton<int>(
                    onChanged: (value) {
                      setState(() {
                        _recurrenceIntervals = value!;
                      });
                      widget.onChanged?.call(
                        _isOneTime ? const OneTime() : Recurring(value!),
                      );
                    },
                    value: _recurrenceIntervals,
                    items: <List<dynamic>>[
                      ['Every Day', Duration(days: 1).inSeconds],
                      ['Every Week', Duration(days: 7).inSeconds],
                      ['Every two Weeks', Duration(days: 14).inSeconds],
                      ['Every Month', Duration(days: 30).inSeconds]
                    ]
                        .map((e) => DropdownMenuItem<int>(
                            value: e[1], child: Text(e[0])))
                        .toList())
            ],
          ),
        ],
      );
}
 */

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
                : caption != null
                    ? caption
                    : null,
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
  })  : this.initialValue =
            initialValue ?? DateRange.monthRange(DateTime.now()),
        this.rangesToShow = rangesToShow ?? [],
        super(key: key);

  @override
  _SimpleDateRangeEditorState createState() => _SimpleDateRangeEditorState();
}

class _SimpleDateRangeEditorState extends State<SimpleDateRangeEditor> {
  // late bool _isOneTime = widget.initialFrequency is OneTime;
  late DateRange _range = widget.initialValue;
  late DateRangeFilter custom =
      DateRangeFilter("Custom", widget.initialValue, FilterLevel.Custom);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.caption != null) widget.caption!,
        Row(
          children: [
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
                if (range != null)
                  setState(() {
                    custom = DateRangeFilter(
                      "Custom",
                      DateRange.fromFlutter(range),
                      FilterLevel.Custom,
                    );
                    _range = DateRange.fromFlutter(range);
                  });
              },
              label: Row(
                  children: const [Icon(Icons.arrow_downward), Text("Custom")]),
            ),
            ...widget.rangesToShow.map(
              (e) => ChoiceChip(
                selected: _range == e.range,
                onSelected: (selected) {
                  if (selected)
                    setState(() {
                      _range = e.range;
                    });
                },
                label: Text(e.name),
              ),
            ),
          ],
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
