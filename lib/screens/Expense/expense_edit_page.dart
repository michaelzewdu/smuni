import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/expense_edit_page.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/widgets/category_selector.dart';
import 'package:smuni/widgets/money_editor.dart';

class ExpenseEditPage extends StatefulWidget {
  static const String routeName = "expenseEdit";

  const ExpenseEditPage({Key? key}) : super(key: key);

  static Route route(String id) => MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (context) => BlocProvider(
          create: (context) =>
              ExpenseEditPageBloc(context.read<ExpenseRepository>(), id),
          child: ExpenseEditPage(),
        ),
      );

  static Route routeNew() => MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) {
        final now = DateTime.now();
        final item = Expense(
          id: "id-${now.microsecondsSinceEpoch}",
          createdAt: now,
          updatedAt: now,
          name: "",
          categoryId: "",
          budgetId: "",
          amount: MonetaryAmount(currency: "ETB", amount: 0),
        );
        return BlocProvider(
          create: (context) => ExpenseEditPageBloc.modified(
              context.read<ExpenseRepository>(), item),
          child: ExpenseEditPage(),
        );
      });

  @override
  State<StatefulWidget> createState() => _ExpenseEditPageState();
}

class _ExpenseEditPageState extends State<ExpenseEditPage> {
  final _formKey = GlobalKey<FormState>();
  int _amountWholes = 0;
  int _amountCents = 0;
  String _name = "";

  String _categoryId = "";
  String _budgetId = "";

  Widget _showForm(BuildContext context, UnmodifiedEditState state) => Form(
        key: _formKey,
        child: Scaffold(
          appBar: AppBar(
            title: Text("Editing expense: ${state.unmodified.name}"),
            actions: [
              ElevatedButton(
                onPressed: () {
                  final form = this._formKey.currentState;
                  if (form != null && form.validate()) {
                    form.save();
                    context.read<ExpenseEditPageBloc>()
                      ..add(
                        ModifyItem(
                          Expense.from(state.unmodified,
                              name: _name,
                              amount: MonetaryAmount(
                                  currency: "ETB",
                                  amount: (_amountWholes * 100) + _amountCents),
                              categoryId: _categoryId,
                              budgetId: _budgetId),
                        ),
                      )
                      ..add(SaveChanges());
                    /* Navigator.popAndPushNamed(
                      context,
                      ExpenseDetailsPage.routeName,
                      arguments: bloc.state.unmodified.id,
                    ); */
                    Navigator.pop(context, true);
                  }
                },
                child: const Text("Save"),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<ExpenseEditPageBloc>().add(DiscardChanges());
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
              MoneyEditor(
                initial: state.unmodified.amount,
                onSavedWhole: (v) => setState(() {
                  _amountWholes = v;
                }),
                onSavedCents: (v) => setState(() {
                  _amountCents = v;
                }),
              ),
              Text("id: ${state.unmodified.id}"),
              Text("createdAt: ${state.unmodified.createdAt}"),
              Text("updatedAt: ${state.unmodified.updatedAt}"),
              // Text("category: ${state.unmodified.categoryId}"),
              CategorySelector(
                initialValue: state.unmodified.categoryId.isEmpty
                    ? null
                    : CategorySelectorState(
                        state.unmodified.categoryId, state.unmodified.budgetId),
                onSaved: (value) {
                  setState(() {
                    _categoryId = value!.id;
                    _budgetId = value.budgetId;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return "No category selected";
                  }
                },
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ExpenseEditPageBloc, ExpenseEditPageBlocState>(
        builder: (context, state) {
          if (state is UnmodifiedEditState) {
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
}
