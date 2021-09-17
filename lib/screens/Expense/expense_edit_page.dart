import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/blocs/expense_edit_page.dart';
import 'package:smuni/models/models.dart';

import 'expense_details_page.dart';

class ExpenseEditPage extends StatefulWidget {
  static const String routeName = "expenseEdit";

  const ExpenseEditPage({Key? key}) : super(key: key);

  static Route route(String id) => MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) {
        final itemsBlock = context.read<ExpensesBloc>();
        final item = (itemsBlock.state as ExpensesLoadSuccess).expenses[id]!;
        return BlocProvider(
          create: (context) => ExpenseEditPageBloc(itemsBlock, item),
          child: ExpenseEditPage(),
        );
      });

  static Route routeNew() => MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) {
        final itemsBlock = context.read<ExpensesBloc>();
        final now = DateTime.now();
        final item = Expense(
          id: "new-id",
          createdAt: now,
          updatedAt: now,
          name: "",
          categoryId: "",
          budgetId: "",
          amount: MonetaryAmount(currency: "ETB", amount: 0),
        );
        return BlocProvider(
          create: (context) => ExpenseEditPageBloc.modified(itemsBlock, item),
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

  @override
  Widget build(BuildContext context) => Form(
        key: _formKey,
        child: Scaffold(
          appBar: AppBar(
            title: BlocBuilder<ExpenseEditPageBloc, ExpenseEditPageBlocState>(
              builder: (context, state) =>
                  Text("Editing expense: ${state.unmodified.name}"),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  final form = this._formKey.currentState;
                  if (form != null && form.validate()) {
                    form.save();
                    final bloc = context.read<ExpenseEditPageBloc>();
                    bloc.add(
                      ModifyItem(
                        Expense.from(bloc.state.unmodified,
                            name: _name,
                            amount: MonetaryAmount(
                                currency: "ETB",
                                amount: (_amountWholes * 100) + _amountCents)),
                      ),
                    );
                    bloc.add(SaveChanges());
                    Navigator.popAndPushNamed(
                      context,
                      ExpenseDetailsPage.routeName,
                      arguments: bloc.state.unmodified.id,
                    );
                    // Navigator.pop(context);
                  }
                },
                child: const Text("Save"),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<ExpenseEditPageBloc>().add(DiscardChanges());
                  Navigator.pop(context);
                },
                child: const Text("Cancel"),
              ),
            ],
          ),
          body: BlocBuilder<ExpenseEditPageBloc, ExpenseEditPageBlocState>(
            builder: (context, state) => Column(
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
                Text("budget: ${state.unmodified.categoryId}"),
                Text("category: ${state.unmodified.categoryId}"),
              ],
            ),
          ),
        ),
      );
}

class MoneyEditor extends StatelessWidget {
  final MonetaryAmount initial;
  final void Function(int) onSavedWhole;
  final void Function(int) onSavedCents;

  const MoneyEditor({
    Key? key,
    required this.onSavedWhole,
    required this.onSavedCents,
    this.initial = const MonetaryAmount(currency: "ETB", amount: 0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: TextFormField(
              textAlign: TextAlign.end,
              keyboardType: TextInputType.numberWithOptions(),
              initialValue: (initial.amount / 100).truncate().toString(),
              onSaved: (value) {
                onSavedWhole(int.parse(value!));
              },
              validator: (value) {
                if (value == null || int.tryParse(value) == null) {
                  return "Must be a whole number";
                }
              },
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: "Amount",
                helperText: "Amount",
                prefix: const Text("ETB"),
              ),
            ),
          ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.3,
            ),
            child: TextFormField(
              inputFormatters: [LengthLimitingTextInputFormatter(2)],
              keyboardType: TextInputType.numberWithOptions(),
              initialValue: (initial.amount % 100).toString(),
              onSaved: (value) {
                onSavedCents(int.parse(value!));
              },
              validator: (value) {
                if (value == null || int.tryParse(value) == null) {
                  return "Not a whole number";
                }
              },
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: "Cents",
                helperText: "Cents",
              ),
            ),
          ),
        ],
      );
}
