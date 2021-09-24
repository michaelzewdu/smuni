import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni/widgets/expense_list_view.dart';

import 'expense_edit_page.dart';

class ExpenseListPage extends StatefulWidget {
  static const String routeName = "/expenseList";

  static Route route() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) => BlocProvider(
        create: (context) => ExpenseListPageBloc(
          context.read<ExpenseRepository>(),
          context.read<CategoryRepository>(),
          const DateRangeFilter(
            "All",
            DateRange(),
            FilterLevel.All,
          ),
        ),
        child: ExpenseListPage(),
      ),
    );
  }

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
              return ExpenseListView(
                items: state.items,
                allDateRanges: state.dateRangeFilters.values,
                displayedRange: state.range,
                loadRange: (range) => context
                    .read<ExpenseListPageBloc>()
                    .add(LoadExpenses(range)),
              );
            }
            return Center(child: CircularProgressIndicator.adaptive());
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(
            context,
            ExpenseEditPage.routeName,
          ),
          child: Icon(Icons.add),
          tooltip: "Add",
        ),
      );
}
