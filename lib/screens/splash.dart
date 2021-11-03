import 'package:flutter/material.dart';

class SplashPage extends StatelessWidget {
  static const String routeName = "/";

  const SplashPage({Key? key}) : super(key: key);

  static Route route() => MaterialPageRoute(
        settings: RouteSettings(name: routeName),
        builder: (context) => SplashPage(),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Text(
                'Kamasio',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              CircularProgressIndicator()
            ],
          ),
        ),
      );
}
