import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smuni/constants.dart';
import 'package:smuni/screens/Budget/budgets_list_screen.dart';
import 'package:smuni/screens/Expense/expense_list_page.dart';

class SmuniHomeScreen extends StatelessWidget {
  SmuniHomeScreen({Key? key}) : super(key: key);

  static const String routeName = '/homeScreen';

  static Route route() {
    return MaterialPageRoute(
        builder: (context) => SmuniHomeScreen(),
        settings: RouteSettings(name: routeName));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
          child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              'Kamasio',
              style: TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w900, color: semuni500),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DrawerButtons(
                    buttonName: 'Budget',
                    drawerButtonAction: () =>
                        Navigator.pushNamed(context, BudgetListPage.routeName),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DrawerButtons(
                      buttonName: 'Expense',
                      drawerButtonAction: () => Navigator.pushNamed(
                          context, ExpenseListPage.routeName)),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DrawerButtons(
                      buttonName: 'About Us',
                      drawerButtonAction: () => print(
                          'This will lead to the About Us screen in the future')),
                )
              ],
            ),
          ],
        ),
      )),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            toolbarHeight: 60,
            title: Text('Home'),
            actions: [
              IconButton(
                  onPressed: () => print('Profile'),
                  icon: Icon(Icons.account_circle_outlined))
            ],
            shape: RoundedRectangleBorder(
                side: BorderSide.none,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(30))),
            expandedHeight: 250,
            pinned: true,
            //floating: true,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 60, 0, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                          text: TextSpan(children: [
                        TextSpan(
                            text: 'Current  ',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w200)),
                        TextSpan(
                            text: 'Standing', style: TextStyle(fontSize: 23))
                      ])),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '-15,000 Br',
                            textScaleFactor: 3,
                            style: TextStyle(backgroundColor: Colors.white),
                          ),
                          Padding(
                              padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                              child: RichText(
                                  text: TextSpan(children: [
                                TextSpan(
                                    text: 'Off ',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w200,
                                        fontSize: 16)),
                                TextSpan(
                                    text: '5000.00 Br',
                                    style: TextStyle(fontSize: 16))
                              ]))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              // margin: EdgeInsets.fromLTRB(8, 8, 0, 8),
              //height: 150,
              children: [
                Container(
                  height: 125,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      HorizontalCards(),
                      HorizontalCards(),
                      HorizontalCards(),
                      HorizontalCards(),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        child: RichText(
                            text: TextSpan(children: [
                          TextSpan(
                              text: 'Total ',
                              style: TextStyle(
                                  fontSize: 23,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w300)),
                          TextSpan(
                              text: 'Spend',
                              style: TextStyle(
                                  fontSize: 23,
                                  color: semuni600,
                                  fontWeight: FontWeight.w600))
                        ])),
                      ),
                      Text('65,099.76 Br',
                          style: TextStyle(fontSize: 23, color: semuni600))
                    ],
                  ),
                )
              ],
            ),
          ),
          SliverList(
              delegate:
                  SliverChildBuilderDelegate((BuildContext context, int index) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Month',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bills',
                        style: TextStyle(fontWeight: FontWeight.w300),
                      ),
                      Text(
                        '2635.12Br',
                        style: TextStyle(fontWeight: FontWeight.w300),
                      )
                    ],
                  ),
                  SizedBox(height: 8),
                  ListTile(
                    leading: Icon(Icons.water),
                    title: Text(
                      'Water',
                      style: TextStyle(fontSize: 20),
                    ),
                    subtitle: Text('Utility'),
                    trailing: Text('-120 Br'),
                  )
                ],
              ),
            );

            /*
            return Container(
              color: index.isOdd ? Colors.white : Colors.black12,
              height: 100.0,
              child: Center(
                child: Text('$index', textScaleFactor: 5),
              ),
            );*/
          }, childCount: 20))
        ],
      ),
    );
  }
}

class DrawerButtons extends StatelessWidget {
  final String buttonName;
  final Function() drawerButtonAction;
  const DrawerButtons(
      {Key? key, required this.buttonName, required this.drawerButtonAction})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: drawerButtonAction,
        child: Text(
          buttonName,
          style: TextStyle(fontSize: 20),
        ),
        style: ElevatedButton.styleFrom(
            fixedSize: Size(250, 60),
            primary: Colors.transparent,
            shadowColor: Colors.transparent,
            onPrimary: semuni500,
            // padding: EdgeInsets.symmetric(vertical: 16, horizontal: 72),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            side: BorderSide(color: semuni500, width: 2)));
  }
}

class HorizontalCards extends StatelessWidget {
  HorizontalCards({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        shadowColor: Colors.green,
        elevation: 3,
        child: SizedBox(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 8, 100, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CBE Wallet',
                  style: TextStyle(fontWeight: FontWeight.w400),
                ),
                SizedBox(
                  height: 8,
                ),
                Text(
                  '12,900 Br',
                  textScaleFactor: 1.6,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 5,
                ),
                Text(
                  'spent 5,000 Birr',
                  style: TextStyle(fontWeight: FontWeight.w300),
                )
                //Text('Spent 5000birr'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
