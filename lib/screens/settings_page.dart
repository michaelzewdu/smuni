import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/constants.dart';
import 'package:smuni/utilities.dart';

import '../constants.dart';

class MenusPage extends StatefulWidget {
  const MenusPage({Key? key}) : super(key: key);

  static const String routeName = '/settings';

  static Route route() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) => MenusPage(),
    );
  }

  @override
  State<MenusPage> createState() => _MenusPageState();
}

class _MenusPageState extends State<MenusPage> {
  var _awaitingOp = false;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          shadowColor: Colors.transparent,
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
          // crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: Text("Kamasio"),
              trailing: Text("0.0.1-alpha"),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: "Smuni",
                applicationVersion: "0.0.1-alpha",
                children: [Text("TODO")],
              ),
            ),
            !_awaitingOp
                ? ElevatedButton(
                    onPressed: () {
                      setState(() => _awaitingOp = true);
                      context.read<SyncBloc>().add(TrySync(
                            onSuccess: () {
                              setState(() => _awaitingOp = false);
                            },
                            onError: (err) {
                              setState(() => _awaitingOp = false);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: err is ConnectionException
                                      ? Text('Connection Failed')
                                      : err is ConnectionException
                                          ? Text('Not Signed In')
                                          : Text('Unknown Error Occured'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ));
                    },
                    child: const Text("Sync"),
                  )
                : const CircularProgressIndicator(),
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
