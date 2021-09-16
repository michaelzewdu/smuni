import 'package:flutter/cupertino.dart';
import 'package:smuni/screens/Budget/budgets_list_screen.dart';
import 'package:smuni/screens/Expense/expense_details_page.dart';
import 'package:smuni/screens/Expense/expense_list_page.dart';
import 'package:smuni/screens/home_screen.dart';
import 'package:smuni/screens/settings_page.dart';

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
        return settings.arguments == null
            ? ExpenseDetailsPage.routeNew()
            : ExpenseDetailsPage.routeView(settings.arguments as String);
      default:
        return SmuniHomeScreen.route();
    }
  }
}
