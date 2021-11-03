import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni/widgets/expense_list_view.dart';

import 'expense_edit_page.dart';

class ExpenseListPage extends StatefulWidget {
  static const String routeName = "/expenseList";

  static Widget page() => BlocProvider(
        create: (context) => ExpenseListPageBloc(
          context.read<ExpenseRepository>(),
          context.read<OfflineExpenseRepository>(),
          context.read<AuthBloc>(),
          context.read<BudgetRepository>(),
          context.read<CategoryRepository>(),
          const DateRangeFilter(
            "All",
            DateRange(),
            FilterLevel.all,
          ),
        ),
        child: ExpenseListPage(),
      );

  static Route route() => MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (context) => ExpenseListPage.page(),
      );

  @override
  State<StatefulWidget> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text("Expenses"),
        ),
        body: BlocBuilder<ExpenseListPageBloc, ExpenseListPageBlocState>(
          builder: (context, state) {
            if (state is ExpensesLoadSuccess) {
              return SingleChildScrollView(
                child: ExpenseListView(
                  items: state.items,
                  allDateRanges: state.dateRangeFilters.values,
                  displayedRange: state.range,
                  onEdit: (id) => Navigator.pushNamed(
                    context,
                    ExpenseEditPage.routeName,
                    arguments: state.items[id],
                  ),
                  onDelete: (id) async {
                    final item = state.items[id]!;
                    final confirm = await showDialog<bool?>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm deletion'),
                        content: Text(
                          'Are you sure you want to delete entry ${item.name}?',
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Confirm'),
                          ),
                        ],
                      ),
                    );
                    if (confirm != null && confirm) {
                      context
                          .read<ExpenseListPageBloc>()
                          .add(DeleteExpense(id));
                    }
                  },
                  loadRange: (range) => context
                      .read<ExpenseListPageBloc>()
                      .add(LoadExpenses(range)),
                ),
              );
            }
            return Center(child: CircularProgressIndicator.adaptive());
          },
        ),
      );
}
