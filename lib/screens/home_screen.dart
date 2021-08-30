import 'package:flutter/material.dart';
import 'package:smuni/screens/Budget/budgets_list_screen.dart';

import 'constants.dart';

class SmuniHomeScreen extends StatelessWidget {
  const SmuniHomeScreen({Key? key}) : super(key: key);

  static const String routeName = 'homeScreen';

  static Route route() {
    return MaterialPageRoute(
        builder: (context) => SmuniHomeScreen(),
        settings: RouteSettings(name: routeName));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
          child: ListView(
        children: [
          DrawerHeader(
              child: Text(
            appName,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24),
          ))
        ],
      )),
      appBar: AppBar(
          title: Text(
        appName,
      )),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Welcome back Mikiyas,',
                style: TextStyle(fontSize: 30),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                    border: Border.all(
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        'Budget',
                        style: TextStyle(fontSize: 18),
                      ),
                      subtitle: Text('Take a look at your budget'),
                      onTap: () {
                        Navigator.pushNamed(context, BudgetListPage.routeName);
                      },
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
