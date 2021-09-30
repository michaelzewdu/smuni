import 'package:flutter/material.dart';

class BudgetEditPage extends StatefulWidget {
  static const String routeName = "budgetEdit";

  const BudgetEditPage({Key? key}) : super(key: key);

  static Route route(String id) => MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (context) => BudgetEditPage(),
      );

  @override
  State<StatefulWidget> createState() => _BudgetEditPageState();
}

class _BudgetEditPageState extends State<BudgetEditPage> {
  @override
  Widget build(BuildContext context) => Center(
        child: Text("TODO"),
      );
}
