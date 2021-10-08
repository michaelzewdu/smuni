import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smuni/blocs/budget_list_page.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/widgets/budget_list_view.dart';

import 'budget_details_page.dart';
import 'budget_edit_page.dart';

class BudgetListPage extends StatefulWidget {
  static const String routeName = "/budgetList";

  static Route route() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) => page(),
    );
  }

  static BlocProvider<BudgetListPageBloc> page() {
    return BlocProvider(
      create: (context) => BudgetListPageBloc(context.read<BudgetRepository>()),
      child: BudgetListPage(),
    );
  }

  @override
  State<StatefulWidget> createState() => _BudgetListPageState();
}

class _BudgetListPageState extends State<BudgetListPage> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text("Budgets"),
        ),
        body: BlocBuilder<BudgetListPageBloc, BudgetListPageBlocState>(
          builder: (context, state) {
            if (state is BudgetsLoadSuccess) {
              return BudgetListView(
                state: state,
                onSelect: (id) => Navigator.pushNamed(
                  context,
                  BudgetDetailsPage.routeName,
                  arguments: id,
                ),
              );
            }
            return Center(child: CircularProgressIndicator.adaptive());
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () =>
              Navigator.pushNamed(context, BudgetEditPage.routeName),
          child: Icon(Icons.add),
          tooltip: "Add",
        ),
      );
}
