// import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smuni/screens/Expense/expense_list_page.dart';

import 'screens/routes.dart';
import 'repositories/repositories.dart';
import 'models/models.dart';
import 'blocs/blocs.dart';
import 'constants.dart';

void main() async {
  /*var user = User(
    id: "cny45347yncx093n24579xm",
    username: "deathconsciousness",
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    email: "shit.flick@lick.shit",
    firebaseId: "holyfukinshit40000",
    phoneNumber: "31415",
    pictureURL: "gemini://bad.bot",
    budgets: [],
    expenses: [],
  );
  print(await sqflite.getDatabasesPath());

  var db = await sqflite.openDatabase("test.db");
  var provider = SqliteUserProvider(db);
  await provider.setItem(user.id, user);
  var out = await provider.getItem(user.id);
  print(out?.toJSON());*/
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final User defaultUser = User(
    id: "614193c7f2ea51b47f5896be",
    username: "superkind",
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    email: "don@key.ote",
    firebaseId: "ABCDEF_123456_ABCDEF_123456_",
    phoneNumber: "+251900112233",
    pictureURL: "https://imagine.co/9q6roh3cifnp",
    budgets: [
      Budget(
        id: "614193c7f2ea51b47f5896ba",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        name: "Monthly budget",
        startTime: DateTime.parse("2021-07-31T21:00:00.000Z"),
        endTime: DateTime.parse("2021-08-31T21:00:00.000Z"),
        allocatedAmount: MonetaryAmount(currency: "ETB", amount: 700000),
        frequency: Recurring(2592000),
        categories: [
          Category(
            id: "614193c7f2ea51b47f5896b8",
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            name: "Medicine",
            parentId: null,
            allocatedAmount: MonetaryAmount(currency: "ETB", amount: 100000),
            tags: ["pharma"],
          ),
          Category(
            id: "614193c7f2ea51b47f5896b9",
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            name: "RejuvPill",
            parentId: "614193c7f2ea51b47f5896b8",
            allocatedAmount: MonetaryAmount(currency: "ETB", amount: 50000),
            tags: [],
          ),
        ],
      ),
      Budget(
        id: "614193c7f2ea51b47f5896bb",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        name: "Special budget",
        startTime: DateTime.parse("2021-07-31T21:00:00.000Z"),
        endTime: DateTime.parse("2021-08-31T21:00:00.000Z"),
        allocatedAmount: MonetaryAmount(currency: "ETB", amount: 1000000),
        frequency: OneTime(),
        categories: [],
      ),
    ],
    expenses: [
      Expense(
        id: "614193c7f2ea51b47f5896bc",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        name: "Pill purchase",
        categoryId: "614193c7f2ea51b47f5896b9",
        budgetId: "614193c7f2ea51b47f5896ba",
        amount: MonetaryAmount(currency: "ETB", amount: 40000),
      ),
      Expense(
        id: "614193c7f2ea51b47f5896bd",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        name: "Xanax purchase",
        categoryId: "614193c7f2ea51b47f5896b8",
        budgetId: "614193c7f2ea51b47f5896ba",
        amount: MonetaryAmount(currency: "ETB", amount: 20000),
      )
    ],
  );
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
        providers: [
          RepositoryProvider(
              create: (context) =>
                  UserRepository()..setItem(defaultUser.id, defaultUser)),
          RepositoryProvider(create: (context) {
            var repo = ExpenseRepository();
            for (var expense in defaultUser.expenses) {
              repo.setItem(expense.id, expense);
            }
            return repo;
          }),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => UsersBloc(defaultUser)),
            BlocProvider(
              create: (context) =>
                  ExpensesBloc(context.read<ExpenseRepository>())
                    ..add(LoadExpenses()),
            ),
          ],
          child: MaterialApp(
            title: 'Smuni',
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate
            ],
            supportedLocales: [
              Locale('en', ''), //English
              Locale('am', ''), //አማርኛ
              Locale('ti', ''), //ትግርኛ
              Locale('aa', ''), //አፋር
              Locale('so', ''), //ሶማሊ
              Locale('sgw', ''), //ሰባት ቤት ጉራጌ
              Locale('sid', ''), //ሲዳሞ
              Locale('wal', ''), //ወላይታ
            ],
            theme: ThemeData(primarySwatch: primarySmuniSwatch),
            home: ExpenseListPage(),
            onGenerateRoute: Routes.myOnGenerateRoute,
          ),
        ),
      );
}
