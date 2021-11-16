import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/widgets/widgets.dart';

import 'budget_details_page.dart';
import 'budget_edit_page.dart';

class BudgetListPage extends StatefulWidget {
  static const String routeName = "/budgetList";
  static const String routeNameArchivedOnly = "/budgetListArchivedOnly";

  static Route route() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) => page(),
    );
  }

  static Route routeArchivedOnly() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) => BlocProvider(
        create: (context) => BudgetListPageBloc(
          context.read<BudgetRepository>(),
          context.read<OfflineBudgetRepository>(),
          const LoadBudgetsFilter(includeActive: false, includeArchvied: true),
        ),
        child: BudgetListPage(
          showingArchivedOnly: true,
        ),
      ),
    );
  }

  static BlocProvider<BudgetListPageBloc> page() {
    return BlocProvider(
      create: (context) => BudgetListPageBloc(
        context.read<BudgetRepository>(),
        context.read<OfflineBudgetRepository>(),
      ),
      child: BudgetListPage(),
    );
  }

  final bool showingArchivedOnly;
  const BudgetListPage({Key? key, this.showingArchivedOnly = false})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _BudgetListPageState();
}

enum BudgetActionsMenuItem { archived }

class _BudgetListPageState extends State<BudgetListPage> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: widget.showingArchivedOnly
              ? const Text("Budget Trash")
              : const Text("Budgets"),
          actions: [
            if (!widget.showingArchivedOnly)
              PopupMenuButton<BudgetActionsMenuItem>(
                  onSelected: (BudgetActionsMenuItem menuItem) {
                    if (menuItem == BudgetActionsMenuItem.archived) {
                      Navigator.pushNamed(
                          context, BudgetListPage.routeNameArchivedOnly);
                    }
                  },
                  itemBuilder: (context) =>
                      <PopupMenuEntry<BudgetActionsMenuItem>>[
                        const PopupMenuItem(
                          value: BudgetActionsMenuItem.archived,
                          child: Text('Trash'),
                        )
                      ])
          ],
        ),
        body: BlocBuilder<BudgetListPageBloc, BudgetListPageBlocState>(
          builder: (context, state) {
            if (state is BudgetsLoadSuccess) {
              return Column(
                children: [
                  /* if (!widget.showingArchivedOnly)
                    ListTile(
                      title: Text("Trash"),
                      dense: true,
                      onTap: () => Navigator.pushNamed(
                          context, BudgetListPage.routeNameArchivedOnly),
                    ), */
                  Expanded(
                    child: BudgetListView(
                      state: state,
                      onSelect: (id) => Navigator.pushNamed(
                        context,
                        BudgetDetailsPage.routeName,
                        arguments: id,
                      ),
                    ),
                  ),
                ],
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
