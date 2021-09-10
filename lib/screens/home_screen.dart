import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SmuniHomeScreen extends StatelessWidget {
  SmuniHomeScreen({Key? key}) : super(key: key);

  static const String routeName = '/homeScreen';

  static Route route() {
    return MaterialPageRoute(
        builder: (context) => SmuniHomeScreen(),
        settings: RouteSettings(name: routeName));
  }

  late TabController _tabController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                            '-15000 Br',
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
            child: Container(
              margin: EdgeInsets.fromLTRB(8, 8, 0, 8),
              height: 150,
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
          ),
          SliverList(
              delegate:
                  SliverChildBuilderDelegate((BuildContext context, int index) {
            return Container(
              color: index.isOdd ? Colors.white : Colors.black12,
              height: 100.0,
              child: Center(
                child: Text('$index', textScaleFactor: 5),
              ),
            );
          }, childCount: 20))
        ],
      ),
    );
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('CBE Wallet'),
              ),
              Text(
                '12,900 Br',
                textScaleFactor: 2,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              //Text('Spent 5000birr'),
            ],
          ),
        ),
      ),
    );
  }
}
