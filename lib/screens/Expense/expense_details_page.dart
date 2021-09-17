import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/models/models.dart';

import 'expense_edit_page.dart';

class ExpenseDetailsPage extends StatelessWidget {
  static const String routeName = "expenseDetails";

  static Route route(String id) => MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) {
        final itemsBlock = context.read<ExpensesBloc>();
        final item = (itemsBlock.state as ExpensesLoadSuccess).expenses[id];
        if (item != null) {
          return ExpenseDetailsPage(item: item);
        } else {
          return const Center(child: const Text("Expense not found"));
        }
      });

  final Expense item;
  const ExpenseDetailsPage({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                ExpenseEditPage.routeName,
                arguments: item.id,
              );
            },
            child: const Text("Edit"),
          ),
          ElevatedButton(
            onPressed: () => showDialog<bool?>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirm deletion'),
                content:
                    Text('Are you sure you want to delete entry ${item.name}?'),
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
                  context.read<ExpensesBloc>().add(DeleteExpense(item.id));
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
          Text(item.name),
          Text("amount: ${item.amount.currency} ${item.amount.amount / 100}"),
          Text("id: ${item.id}"),
          Text("budget: ${item.categoryId}"),
          Text("category: ${item.categoryId}"),
          Text("createdAt: ${item.createdAt}"),
          Text("updatedAt: ${item.updatedAt}"),
        ],
      ),
    );
  }
}
