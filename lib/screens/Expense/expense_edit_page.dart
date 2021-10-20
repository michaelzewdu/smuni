import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/edit_page/expense_edit_page.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni/widgets/money_editor.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

class ExpenseEditPageNewArgs {
  final String budgetId;
  final String categoryId;

  const ExpenseEditPageNewArgs(
      {required this.budgetId, required this.categoryId});
}

class ExpenseEditPage extends StatefulWidget {
  static const String routeName = "expenseEdit";

  final Expense item;
  final bool isCreating;

  const ExpenseEditPage({
    Key? key,
    required this.item,
    required this.isCreating,
  }) : super(key: key);

  static Route route(Expense item) => MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (context) => BlocProvider(
          create: (context) =>
              ExpenseEditPageBloc(context.read<ExpenseRepository>()),
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
          name: "",
          timestamp: now,
          categoryId: args.categoryId,
          budgetId: args.budgetId,
          amount: MonetaryAmount(currency: "ETB", amount: 0),
        );
        return BlocProvider(
          create: (context) => ExpenseEditPageBloc(
            context.read<ExpenseRepository>(),
          ),
          child: ExpenseEditPage(item: item, isCreating: true),
        );
      });

  @override
  State<StatefulWidget> createState() => _ExpenseEditPageState();
}

class _ExpenseEditPageState extends State<ExpenseEditPage> {
  final _formKey = GlobalKey<FormState>();

  late var _amount = widget.item.amount;
  late var _name = widget.item.name;
  late DateTime _timestamp = widget.item.timestamp;

  bool _awaitingSave = false;

  @override
  Widget build(context) =>
      BlocListener<ExpenseEditPageBloc, ExpenseEditPageBlocState>(
        listener: (context, state) {
          if (state is ExpenseEditSuccess) {
            if (_awaitingSave) setState(() => {_awaitingSave = false});
            Navigator.pop(context);
          } else if (state is ExpenseEditFailed) {
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
          } else {
            throw Exception("Unhandled type");
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: _awaitingSave
                ? const Text("Loading...")
                : Text("Editing expense: ${widget.item.name}"),
            actions: [
              ElevatedButton(
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
                TextFormField(
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
                MoneyFormEditor(
                  initialValue: _amount,
                  onSaved: (v) => setState(() => _amount = v!),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal:8.0),
                    decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(15)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Time: "),
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
                ),
                Text("id: ${widget.item.id}"),
                Text("createdAt: ${widget.item.createdAt}"),
                Text("updatedAt: ${widget.item.updatedAt}"),
                Text("budget: ${widget.item.budgetId}"),
                Text("category: ${widget.item.categoryId}"),
              ],
            ),
          ),
        ),
      );
}

String humanReadableDayRelationName(
  DateTime time,
  DateTime relativeTo,
) {
  final diff = time.difference(relativeTo);
  if (diff.inDays < -7) {
    return '${monthNames[time.month]} ${time.day} ${time.year}';
  }
  if (diff.inDays <= -2) return '${diff.inDays.abs()} days ago';
  if (relativeTo.day - 1 == time.day) return 'Yesterday';
  return 'Today';
}

String humanReadableTimeRelationName(
  DateTime time,
  DateTime relativeTo,
) {
  final diff = time.difference(relativeTo);
  if (diff.inDays < -7) {
    return '${monthNames[time.month]} ${time.day} ${time.year}';
  }
  if (diff.inDays > -2) return '${diff.inDays.abs()} days ago';
  if (diff.inDays < -1 && relativeTo.day - 1 == time.day) return 'Yesterday';
  if (diff.inHours < -1) return '${diff.inHours.abs()} hours ago';
  if (diff.inMinutes < -1) return '${diff.inMinutes.abs()} minutes ago';
  return 'Now';
}
