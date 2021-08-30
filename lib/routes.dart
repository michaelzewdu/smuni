import 'package:flutter/cupertino.dart';
import 'package:smuni/screens/Budget/budgets_list_screen.dart';
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
      default:
        return SmuniHomeScreen.route();
    }
  }
}
