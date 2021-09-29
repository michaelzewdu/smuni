import 'package:flutter/material.dart';
import 'package:smuni/models/models.dart';

class BudgetDetails extends StatelessWidget {
  BudgetDetails({Key? key}) : super(key: key);

  static const String routeName = '/budgetDetail';
  Budget? thisBudget;

  static Route route() {
    return MaterialPageRoute(
        builder: (context) => BudgetDetails(),
        settings: RouteSettings(name: routeName));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [],
    );
  }
}
