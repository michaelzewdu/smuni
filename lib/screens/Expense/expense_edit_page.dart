import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smuni/blocs/edit_page.dart';

import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/widgets/money_editor.dart';

class ExpenseEditPageNewArgs {
  final String budgetId;
  final String categoryId;

  const ExpenseEditPageNewArgs(
      {required this.budgetId, required this.categoryId});
}

class ExpenseEditPage extends StatefulWidget {
  static const String routeName = "expenseEdit";

  const ExpenseEditPage({Key? key}) : super(key: key);

  static Route route(String id) => MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (context) => BlocProvider(
          create: (context) =>
              EditPageBloc.fromRepo(context.read<ExpenseRepository>(), id),
          child: ExpenseEditPage(),
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
          categoryId: args.categoryId,
          budgetId: args.budgetId,
          amount: MonetaryAmount(currency: "ETB", amount: 0),
        );
        return BlocProvider(
          create: (context) =>
              EditPageBloc.modified(context.read<ExpenseRepository>(), item),
          child: ExpenseEditPage(),
        );
      });

  @override
  State<StatefulWidget> createState() => _ExpenseEditPageState();
}

class _ExpenseEditPageState extends State<ExpenseEditPage> {
  final _formKey = GlobalKey<FormState>();
  MonetaryAmount _amount = MonetaryAmount(currency: "ETB", amount: 0);
  String _name = "";

  Widget _showForm(
          BuildContext context, UnmodifiedEditState<String, Expense> state) =>
      Form(
        key: _formKey,
        child: Scaffold(
          appBar: AppBar(
            title: Text("Editing expense: ${state.unmodified.name}"),
            actions: [
              ElevatedButton(
                onPressed: () {
                  final form = _formKey.currentState;
                  if (form != null && form.validate()) {
                    form.save();
                    context.read<EditPageBloc<String, Expense>>()
                      ..add(
                        ModifyItem<String, Expense>(
                          Expense.from(
                            state.unmodified,
                            name: _name,
                            amount: _amount,
                          ),
                        ),
                      )
                      ..add(SaveChanges<String, Expense>());
                    Navigator.pop(context, true);
                  }
                },
                child: const Text("Save"),
              ),
              ElevatedButton(
                onPressed: () {
                  context
                      .read<EditPageBloc<String, Expense>>()
                      .add(DiscardChanges());
                  Navigator.pop(context, false);
                },
                child: const Text("Cancel"),
              ),
            ],
          ),
          body: Column(
            children: <Widget>[
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
                initialValue: state.unmodified.amount,
                onSaved: (v) => setState(() => _amount = v!),
              ),
              Text("id: ${state.unmodified.id}"),
              Text("createdAt: ${state.unmodified.createdAt}"),
              Text("updatedAt: ${state.unmodified.updatedAt}"),
              Text("budget: ${state.unmodified.budgetId}"),
              Text("category: ${state.unmodified.categoryId}"),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => BlocBuilder<
          EditPageBloc<String, Expense>, EditPageBlocState<String, Expense>>(
        builder: (context, state) {
          if (state is UnmodifiedEditState<String, Expense>) {
            return _showForm(context, state);
          } else if (state is LoadingItem) {
            return Scaffold(
              appBar: AppBar(
                title: const Text("Loading expense..."),
              ),
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (state is ItemNotFound<String, Expense>) {
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
