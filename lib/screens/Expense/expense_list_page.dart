import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/blocs.dart';

import 'expense_details_page.dart';
import 'expense_edit_page.dart';

class ExpenseListPage extends StatefulWidget {
  static const String routeName = "expenseList";

  static Route route() {
    return MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (context) => ExpenseListPage());
  }

  @override
  State<StatefulWidget> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text("Expenses"),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  ExpenseEditPage.routeName,
                );
              },
              child: const Text("New"),
            )
          ],
        ),
        body: BlocBuilder<ExpensesBloc, ExpensesBlocState>(
          builder: (context, state) {
            if (state is ExpensesLoadSuccess) {
              final items = state.items;
              final keys = items.keys;
              return Container(
                child: items.isNotEmpty
                    ? ListView.builder(
                        itemCount: keys.length,
                        itemBuilder: (context, index) {
                          final item = items[keys.elementAt(index)]!;
                          return ListTile(
                            title: Text(item.name),
                            subtitle: Text(
                              "${item.amount.currency} ${item.amount.amount / 100}",
                            ),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                ExpenseDetailsPage.routeName,
                                arguments: item.id,
                              );
                            },
                          );
                        },
                      )
                    : Center(child: const Text("No expenses.")),
              );
            }
            return Center(child: CircularProgressIndicator.adaptive());
          },
        ),
      );
}
