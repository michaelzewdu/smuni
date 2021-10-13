import 'package:flutter/material.dart';
import 'package:smuni/constants.dart';

class MenusPage extends StatelessWidget {
  const MenusPage({Key? key}) : super(key: key);

  static const String routeName = '/settings';

  static Route route() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) => MenusPage(),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            'Kamasio',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DrawerButtons(
                buttonName: 'About Us',
                drawerButtonAction: () => showAboutDialog(
                  context: context,
                  applicationName: "Smuni",
                  applicationVersion: "0.0.1-alpha",
                  children: [Text("TODO")],
                ),
              ),
            ),
          ],
        ),
      );
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
