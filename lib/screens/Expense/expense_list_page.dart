import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/widgets/expense_list_view.dart';

import '../../constants.dart';
import 'expense_edit_page.dart';

class ExpenseListPage extends StatefulWidget {
  static const String routeName = "/expenseList";

  static Widget page() => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => ExpenseListPageBloc(
              context.read<ExpenseRepository>(),
              context.read<OfflineExpenseRepository>(),
              context.read<AuthBloc>(),
              context.read<BudgetRepository>(),
              context.read<CategoryRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => CategoryListPageBloc(
              context.read<CategoryRepository>(),
              context.read<OfflineCategoryRepository>(),
              LoadCategoriesFilter(
                includeActive: true,
                includeArchvied: true,
              ),
            ),
          ),
          BlocProvider(
            create: (context) => BudgetListPageBloc(
              context.read<BudgetRepository>(),
              context.read<OfflineBudgetRepository>(),
              LoadBudgetsFilter(
                includeActive: true,
                includeArchvied: true,
              ),
            ),
          ),
        ],
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
          backgroundColor: semuni50,
          foregroundColor: Colors.black,
          shadowColor: Colors.transparent,
          title: const Text("Expenses"),
        ),
        body: BlocBuilder<ExpenseListPageBloc, ExpenseListPageBlocState>(
          builder: (context, expensesState) => expensesState
                  is ExpensesLoadSuccess
              ? BlocBuilder<BudgetListPageBloc, BudgetListPageBlocState>(
                  builder: (context, budgetsState) => budgetsState
                          is BudgetsLoadSuccess
                      ? BlocBuilder<CategoryListPageBloc,
                          CategoryListPageBlocState>(
                          builder: (context, categoriesState) => categoriesState
                                  is CategoriesLoadSuccess
                              ? SingleChildScrollView(
                                  child: ExpenseListView(
                                    items: expensesState.items,
                                    allBudgets: budgetsState.items,
                                    allCategories: categoriesState.items,
                                    allDateRanges:
                                        expensesState.dateRangeFilters.values,
                                    displayedRange: expensesState.filter.range,
                                    onEdit: (id) => Navigator.pushNamed(
                                      context,
                                      ExpenseEditPage.routeName,
                                      arguments: expensesState.items[id],
                                    ),
                                    onDelete: (id) async {
                                      final item = expensesState.items[id]!;
                                      final confirm = await showDialog<bool?>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Confirm deletion'),
                                          content: Text(
                                            'Are you sure you want to delete entry ${item.name}?',
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
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
                                        .add(LoadExpenses(
                                            filter: LoadExpensesFilter(
                                                range: range))),
                                  ),
                                )
                              : categoriesState is CategoriesLoading
                                  ? Center(
                                      child:
                                          CircularProgressIndicator.adaptive())
                                  : throw Exception(
                                      "Unhandled state: $categoriesState"),
                        )
                      : budgetsState is BudgetsLoading
                          ? Center(child: CircularProgressIndicator.adaptive())
                          : throw Exception("Unhandled state: $budgetsState"),
                )
              : expensesState is ExpensesLoading
                  ? Center(child: CircularProgressIndicator.adaptive())
                  : throw Exception("Unhandled state: $expensesState"),
        ),
      );
}
