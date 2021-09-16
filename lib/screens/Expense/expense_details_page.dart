import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/models/models.dart';

class ExpenseDetailsPage extends StatefulWidget {
  static const String routeName = "expenseDetails";

  const ExpenseDetailsPage({Key? key}) : super(key: key);

  static Route routeView(String id) => MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) {
        final itemsBlock = context.read<ExpensesBloc>();
        final item = (itemsBlock.state as ExpensesLoadSuccess).expenses[id]!;
        return BlocProvider(
          create: (context) => ExpenseDetailsPageBloc(itemsBlock, item),
          child: ExpenseDetailsPage(),
        );
      });

  static Route routeNew() => MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) {
        final itemsBlock = context.read<ExpensesBloc>();
        final item = Expense(
          id: "",
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          name: "",
          categoryId: "",
          budgetId: "",
          amount: MonetaryAmount(currency: "ETB", amount: 0),
        );
        return BlocProvider(
          create: (context) =>
              ExpenseDetailsPageBloc(itemsBlock, item)..add(StartEditing()),
          child: ExpenseDetailsPage(),
        );
      });

  @override
  State<StatefulWidget> createState() => _ExpenseDetailsPageState();
}

class _ExpenseDetailsPageState extends State<ExpenseDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ExpenseDetailsPageBloc, ExpenseDetailsPageBlocState>(
          builder: (context, state) {
        final item = state is ViewingExpense
            ? state.item
            : state is EditingExpense
                ? state.modified
                : throw Exception("unexpected state");

        final isEditing = state is EditingExpense;

        if (isEditing) {
          return Scaffold(
            appBar: AppBar(
              title: Text("Editing expense: ${item.name}"),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    context.read<ExpenseDetailsPageBloc>().add(SaveChanges());
                  },
                  child: const Text("Save"),
                ),
                ElevatedButton(
                  onPressed: () {
                    context
                        .read<ExpenseDetailsPageBloc>()
                        .add(DiscardChanges());
                  },
                  child: const Text("Cancel"),
                ),
              ],
            ),
            body: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    initialValue: item.name,
                    onChanged: (value) {
                      context
                          .read<ExpenseDetailsPageBloc>()
                          .add(ModifyItem(Expense.from(item, name: value)));
                    },
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: "Name",
                      helperText: "Name",
                    ),
                  ),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    initialValue: item.amount.amount.toString(),
                    onChanged: (value) {
                      context
                          .read<ExpenseDetailsPageBloc>()
                          .add(ModifyItem(Expense.from(item, name: value)));
                    },
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: "Amount",
                      helperText: "Amount",
                      prefix: const Text("ETB "),
                    ),
                  ),
                  Text("id: ${item.id}"),
                  Text("createdAt: ${item.createdAt}"),
                  Text("updatedAt: ${item.updatedAt}"),
                  Text("budget: ${item.categoryId}"),
                  Text("category: ${item.categoryId}"),
                ],
              ),
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              title: Text(item.name),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    context.read<ExpenseDetailsPageBloc>().add(StartEditing());
                  },
                  child: const Text("Edit"),
                )
              ],
            ),
            body: Column(
              children: <Widget>[
                Text(item.name),
                Text("amount: ${item.amount.currency} ${item.amount.amount}"),
                Text("id: ${item.id}"),
                Text("budget: ${item.categoryId}"),
                Text("category: ${item.categoryId}"),
                Text("createdAt: ${item.createdAt}"),
                Text("updatedAt: ${item.updatedAt}"),
              ],
            ),
          );
        }
      });
}
