import 'package:flutter/material.dart';

class BudgetDetails extends StatelessWidget {
  const BudgetDetails({Key? key}) : super(key: key);

  static const String routeName = '/budgetDetail';

  static Route route() {
    return MaterialPageRoute(
        builder: (context) => BudgetDetails(),
        settings: RouteSettings(name: routeName));
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
