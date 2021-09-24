import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni/widgets/expense_list_view.dart';

import 'category_edit_page.dart';

class CategoryDetailsPage extends StatelessWidget {
  static const String routeName = "categoryDetails";

  static Route route(String id) => MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (context) => BlocProvider(
          create: (context) => DetailsPageBloc<String, Category>(
              context.read<CategoryRepository>(), id),
          child: BlocProvider(
            create: (context) => ExpenseListPageBloc(
              context.read<ExpenseRepository>(),
              context.read<CategoryRepository>(),
              const DateRangeFilter(
                "All",
                DateRange(),
                FilterLevel.All,
              ),
              id,
            ),
            child: CategoryDetailsPage(),
          ),
        ),
      );

  const CategoryDetailsPage({Key? key}) : super(key: key);

  Widget _showDetails(
    BuildContext context,
    LoadSuccess<String, Category> state,
  ) =>
      Scaffold(
        appBar: AppBar(
          title: Text(state.item.name),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                CategoryEditPage.routeName,
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
                        .read<DetailsPageBloc<String, Category>>()
                        .add(DeleteItem());
                    Navigator.pop(context);
                  }
                },
              ),
              child: const Text("Delete"),
            )
          ],
        ),
        body: BlocBuilder<ExpenseListPageBloc, ExpenseListPageBlocState>(
          builder: (context, expensesState) => Column(
            children: <Widget>[
              Text(state.item.name),
              expensesState is ExpensesLoadSuccess
                  ? Builder(builder: (context) {
                      final currency = state.item.allocatedAmount.currency;
                      final totalAlocated = state.item.allocatedAmount.amount;
                      final totalUsed = expensesState.items.values
                          .map((e) => e.amount.amount)
                          .reduce((a, b) => a + b);
                      return Column(
                        children: [
                          Text(
                            "Allocated:  $currency ${totalAlocated / 100}",
                          ),
                          Text(
                            "Used:  $currency ${totalUsed / 100}",
                          ),
                          Text(
                            "Remaining:  $currency ${(totalAlocated - totalUsed) / 100}",
                          ),
                          LinearProgressIndicator(
                            value: totalUsed / totalAlocated,
                          )
                        ],
                      );
                    })
                  : const Text("Loading expenses..."),
              Text("id: ${state.item.id}"),
              Text("budget: ${state.item.budgetId}"),
              Text("tags: ${state.item.tags}"),
              Text("createdAt: ${state.item.createdAt}"),
              Text("updatedAt: ${state.item.updatedAt}"),
              Column(
                children: expensesState is ExpensesLoadSuccess
                    ? [
                        const Text("Expenses:"),
                        ExpenseListView(
                          items: expensesState.items,
                          allDateRanges: expensesState.dateRangeFilters.values,
                          displayedRange: expensesState.range,
                          loadRange: (range) => context
                              .read<ExpenseListPageBloc>()
                              .add(LoadExpenses(range, state.item.id)),
                        )
                      ]
                    : [
                        const Text("Loading expenses..."),
                        Center(child: CircularProgressIndicator.adaptive())
                      ],
              ),
            ],
          ),
        ),
      );
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DetailsPageBloc<String, Category>, DetailsPageState>(
        builder: (context, state) {
          if (state is LoadSuccess<String, Category>) {
            return _showDetails(context, state);
          } else if (state is LoadingItem) {
            return Scaffold(
              appBar: AppBar(
                title: const Text("Loading category..."),
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
