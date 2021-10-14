// FIXME: most of these won't be need to be routed after the nav bar update

import 'package:flutter/widgets.dart';

import 'package:smuni/models/models.dart';

import 'Budget/budget_details_page.dart';
import 'Budget/budget_edit_page.dart';
import 'Budget/budget_list_page.dart';
import 'Category/category_details_page.dart';
import 'Category/category_edit_page.dart';
import 'Category/category_list_page.dart';
import 'Expense/expense_details_page.dart';
import 'Expense/expense_edit_page.dart';
import 'Expense/expense_list_page.dart';
import 'home_screen.dart';
import 'settings_page.dart';

class Routes {
  static Route myOnGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case SmuniHomeScreen.routeName:
        return SmuniHomeScreen.route();
      case MenusPage.routeName:
        return MenusPage.route();
      case BudgetListPage.routeName:
        return BudgetListPage.route();
      case BudgetDetailsPage.routeName:
        return BudgetDetailsPage.route(settings.arguments as String);
      case BudgetEditPage.routeName:
        return settings.arguments == null
            ? BudgetEditPage.routeNew()
            : BudgetEditPage.route(settings.arguments as Budget);
      case ExpenseListPage.routeName:
        return ExpenseListPage.route();
      case ExpenseDetailsPage.routeName:
        return ExpenseDetailsPage.route(settings.arguments as String);
      case ExpenseEditPage.routeName:
        if (settings.arguments == null) {
          throw Exception("Was expecting arguments found for route");
        }
        return settings.arguments is ExpenseEditPageNewArgs
            ? ExpenseEditPage.routeNew(
                settings.arguments as ExpenseEditPageNewArgs)
            : ExpenseEditPage.route(settings.arguments as Expense);
      case CategoryListPage.routeName:
        return CategoryListPage.route();
      case CategoryDetailsPage.routeName:
        return CategoryDetailsPage.route(settings.arguments as String);
      case CategoryEditPage.routeName:
        return settings.arguments == null
            ? CategoryEditPage.routeNew()
            : CategoryEditPage.route(settings.arguments as Category);
      default:
        return SmuniHomeScreen.route();
    }
  }
}
