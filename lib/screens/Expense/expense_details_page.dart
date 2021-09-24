import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';

import 'expense_edit_page.dart';

class ExpenseDetailsPage extends StatelessWidget {
  static const String routeName = "expenseDetails";

  static Route route(String id) => MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (context) => BlocProvider(
          create: (context) => DetailsPageBloc<String, Expense>(
              context.read<ExpenseRepository>(), id),
          child: ExpenseDetailsPage(),
        ),
      );

  const ExpenseDetailsPage({Key? key}) : super(key: key);

  Widget _showDetails(
    BuildContext context,
    LoadSuccess<String, Expense> state,
  ) =>
      Scaffold(
        appBar: AppBar(
          title: Text(state.item.name),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                ExpenseEditPage.routeName,
                arguments: state.item.id,
              ),
              child: const Text("Edit"),
            ),
            ElevatedButton(
              onPressed: () => showDialog<bool?>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm deletion'),
                  content: Text(
                      'Are you sure you want to delete entry ${state.item.name}?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      child: const Text('Confirm'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ).then(
                (confirm) {
                  if (confirm != null && confirm) {
                    context
                        .read<DetailsPageBloc<String, Expense>>()
                        .add(DeleteItem());
                    Navigator.pop(context);
                  }
                },
              ),
              child: const Text("Delete"),
            )
          ],
        ),
        body: Column(
          children: <Widget>[
            Text(state.item.name),
            Text(
                "amount: ${state.item.amount.currency} ${state.item.amount.amount / 100}"),
            Text("id: ${state.item.id}"),
            Text("budget: ${state.item.categoryId}"),
            Text("category: ${state.item.categoryId}"),
            Text("createdAt: ${state.item.createdAt}"),
            Text("updatedAt: ${state.item.updatedAt}"),
          ],
        ),
      );
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DetailsPageBloc<String, Expense>, DetailsPageState>(
        builder: (context, state) {
          if (state is LoadSuccess<String, Expense>) {
            return _showDetails(context, state);
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
