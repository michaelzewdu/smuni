import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/constants.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni/widgets/widgets.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

class IncomeEditPage extends StatefulWidget {
  static const String routeName = "/incomeEdit";

  final Income item;
  final bool isCreating;

  const IncomeEditPage({
    Key? key,
    required this.item,
    required this.isCreating,
  }) : super(key: key);

  static Route route(Income item) => MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (context) => BlocProvider(
          create: (context) => IncomeEditPageBloc(
            context.read<IncomeRepository>(),
            context.read<OfflineIncomeRepository>(),
            context.read<AuthBloc>(),
          ),
          child: IncomeEditPage(
            item: item,
            isCreating: false,
          ),
        ),
      );

  static Route routeNew() => MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) {
        final now = DateTime.now();
        final item = Income(
          id: "id-${now.microsecondsSinceEpoch}",
          createdAt: now,
          updatedAt: now,
          name: "",
          timestamp: now,
          frequency: OneTime(),
          amount: MonetaryAmount(currency: "ETB", amount: 0),
        );
        return BlocProvider(
          create: (context) => IncomeEditPageBloc(
            context.read<IncomeRepository>(),
            context.read<OfflineIncomeRepository>(),
            context.read<AuthBloc>(),
          ),
          child: IncomeEditPage(item: item, isCreating: true),
        );
      });

  @override
  State<StatefulWidget> createState() => _IncomeEditPageState();
}

class _IncomeEditPageState extends State<IncomeEditPage> {
  final _formKey = GlobalKey<FormState>();

  late var _amount = widget.item.amount;
  late var _name = widget.item.name;
  late DateTime _timestamp = widget.item.timestamp;
  late var _frequency = widget.item.frequency;
  late var _isOneTime = widget.item.frequency is OneTime;

  bool _awaitingSave = false;

  @override
  Widget build(context) =>
      BlocListener<IncomeEditPageBloc, IncomeEditPageBlocState>(
        listener: (context, state) {
          if (state is IncomeEditSuccess) {
            if (_awaitingSave) setState(() => {_awaitingSave = false});
            Navigator.pop(context);
          } else if (state is IncomeEditFailed) {
            if (_awaitingSave) setState(() => {_awaitingSave = false});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: state.error is ConnectionException
                    ? Text('Connection Failed')
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
                : FittedBox(child: Text(widget.item.name)),
            actions: [
              ElevatedButton(
                child: const Text("Save"),
                onPressed: !_awaitingSave
                    ? () {
                        final form = _formKey.currentState;
                        if (form != null && form.validate()) {
                          form.save();
                          if (widget.isCreating) {
                            context.read<IncomeEditPageBloc>().add(
                                  CreateIncome(CreateIncomeInput(
                                    name: _name,
                                    frequency: _frequency,
                                    amount: _amount,
                                    timestamp: _timestamp,
                                  )),
                                );
                          } else {
                            context.read<IncomeEditPageBloc>().add(
                                  UpdateIncome(
                                    widget.item.id,
                                    UpdateIncomeInput.fromDiff(
                                      update: Income.from(
                                        widget.item,
                                        name: _name,
                                        amount: _amount,
                                        frequency: _frequency,
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
              ElevatedButton(
                child: !_awaitingSave
                    ? const Text("Cancel")
                    : const CircularProgressIndicator(),
                onPressed:
                    !_awaitingSave ? () => Navigator.pop(context, false) : null,
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(12.0),
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
                      border: const OutlineInputBorder(),
                      hintText: "Name",
                      helperText: "Name",
                    ),
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
              ],
            ),
          ),
        ),
      );

  Widget _recurringDateRangeSelctor(BuildContext context) {
    return SimpleDateRangeFormEditor(
      initialValue: _frequency is Recurring
          ? DateRange(
              startTime: _timestamp.millisecondsSinceEpoch,
              endTime: (_frequency as Recurring).recurringIntervalSecs * 1000,
            )
          : DateRange(
              startTime: _timestamp.millisecondsSinceEpoch,
              endTime: _timestamp.millisecondsSinceEpoch +
                  Duration(days: 1).inMilliseconds,
            ),
      rangesToShow: [
        DateRangeFilter(
            "Every Day",
            DateRange(
              startTime: _timestamp.millisecondsSinceEpoch,
              endTime: _timestamp.millisecondsSinceEpoch +
                  Duration(days: 1).inMilliseconds,
            ),
            FilterLevel.day),
        DateRangeFilter(
            "Every Week",
            DateRange(
              startTime: _timestamp.millisecondsSinceEpoch,
              endTime: _timestamp.millisecondsSinceEpoch +
                  Duration(days: 7).inMilliseconds,
            ),
            FilterLevel.week),
        DateRangeFilter(
            "Every Two Weeks",
            DateRange(
              startTime: _timestamp.millisecondsSinceEpoch,
              endTime: _timestamp.millisecondsSinceEpoch +
                  Duration(days: 14).inMilliseconds,
            ),
            FilterLevel.week),
        DateRangeFilter(
          "Every Month",
          DateRange(
            startTime: _timestamp.millisecondsSinceEpoch,
            endTime: _timestamp.millisecondsSinceEpoch +
                Duration(days: 30).inMilliseconds,
          ),
          FilterLevel.month,
        ),
      ],
      validator: (range) {
        if (range == null) return "Day range not selected";
      },
      onSaved: (range) => setState(() {
        _timestamp = range!.start;
        _frequency = Recurring(range.duration.inSeconds);
      }),
    );
  }

  Widget _oneTimeDateRangeSelctor(BuildContext context) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
              border: Border.all(), borderRadius: BorderRadius.circular(15)),
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
                  }
                },
                icon: Icon(Icons.edit),
              ),
            ],
          ),
        ),
      );
}
