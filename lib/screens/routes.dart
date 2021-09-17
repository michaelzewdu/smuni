import 'package:flutter/widgets.dart';

import 'Budget/budgets_list_screen.dart';
import 'Expense/expense_details_page.dart';
import 'Expense/expense_list_page.dart';
import 'Expense/expense_edit_page.dart';
import 'home_screen.dart';
import 'settings_page.dart';

class Routes {
  static Route myOnGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case SmuniHomeScreen.routeName:
        return SmuniHomeScreen.route();
      case SettingsPage.routeName:
        return SettingsPage.route();
      case BudgetListPage.routeName:
        return BudgetListPage.route();
      case ExpenseListPage.routeName:
        return ExpenseListPage.route();
      case ExpenseDetailsPage.routeName:
        return ExpenseDetailsPage.route(settings.arguments as String);
      case ExpenseEditPage.routeName:
        return settings.arguments == null
            ? ExpenseEditPage.routeNew()
            : ExpenseEditPage.route(settings.arguments as String);
      default:
        return SmuniHomeScreen.route();
    }
  }
}
