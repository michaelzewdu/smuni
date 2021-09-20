import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/blocs/expense_edit_page.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/widgets/category_selector.dart';
import 'package:smuni/widgets/money_editor.dart';

class ExpenseEditPage extends StatefulWidget {
  static const String routeName = "expenseEdit";

  const ExpenseEditPage({Key? key}) : super(key: key);

  static Route route(String id) => MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) {
        final itemsBlock = context.read<ExpensesBloc>();
        final item = (itemsBlock.state as ExpensesLoadSuccess).items[id]!;

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

  String _categoryId = "";
  String _budgetId = "";

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
                                amount: (_amountWholes * 100) + _amountCents),
                            categoryId: _categoryId,
                            budgetId: _budgetId),
                      ),
                    );
                    bloc.add(SaveChanges());
                    /* Navigator.popAndPushNamed(
                      context,
                      ExpenseDetailsPage.routeName,
                      arguments: bloc.state.unmodified.id,
                    ); */
                    Navigator.pop(context);
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
                // Text("category: ${state.unmodified.categoryId}"),
                CategorySelector(
                  initialValue: state.unmodified.categoryId.isEmpty
                      ? null
                      : CategorySelectorState(state.unmodified.categoryId,
                          state.unmodified.budgetId),
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
        ),
      );
}
