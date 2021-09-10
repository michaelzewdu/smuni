import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smuni/routes.dart';
import 'package:smuni/screens/home_screen.dart';

import 'constants.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Semuni',
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: [
        Locale('en',''), //English
        Locale('am',''), //አማርኛ
        Locale('ti',''), //ትግርኛ
        Locale('aa',''), //አፋር
        Locale('so',''), //ሶማሊ
        Locale('sgw',''), //ሰባት ቤት ጉራጌ
        Locale('sid',''), //ሲዳሞ
        Locale('wal',''), //ወላይታ
        


      ],
      theme: ThemeData(

          primarySwatch: primarySmuniSwatch),
      home: SmuniHomeScreen(),
      onGenerateRoute: Routes.myOnGenerateRoute,
    );
  }
}
