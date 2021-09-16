import 'package:flutter/material.dart';

class BudgetListPage extends StatelessWidget {
  const BudgetListPage({Key? key}) : super(key: key);

  static const String routeName = '/budgetListScreen';

  static Route route() {
    return MaterialPageRoute(
        settings: RouteSettings(name: routeName),
        builder: (context) => BudgetListPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budgets List'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {  },
        child: Icon(
          Icons.add
        ),
      ),
    );
  }
}
