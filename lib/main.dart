import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'bloc_observer.dart';
import 'screens/home_screen.dart';
import 'screens/routes.dart';
import 'repositories/repositories.dart';
import 'models/models.dart';
import 'blocs/blocs.dart';
import 'constants.dart';

void main() async {
  Bloc.observer = SimpleBlocObserver();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final User defaultUser = (() {
    final now = DateTime.now();
    return User(
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
          allocatedAmount: MonetaryAmount(currency: "ETB", amount: 7000 * 100),
          frequency: Recurring(2592000),
          categories: {
            "fpoq3cum4cpu43241u34":
                MonetaryAmount(currency: "ETB", amount: 1000 * 100),
            "mucpxo2ur3p98u32proxi34":
                MonetaryAmount(currency: "ETB", amount: 300 * 100),
            "614193c7f2ea51b47f5896b8":
                MonetaryAmount(currency: "ETB", amount: 1000 * 100),
            "614193c7f2ea51b47f5896b9":
                MonetaryAmount(currency: "ETB", amount: 500 * 100)
          },
        ),
        Budget(
          id: "614193c7f2ea51b47f5896bb",
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          name: "Special budget",
          startTime: DateTime.parse("2021-07-31T21:00:00.000Z"),
          endTime: DateTime.parse("2021-08-31T21:00:00.000Z"),
          allocatedAmount: MonetaryAmount(currency: "ETB", amount: 2000 * 100),
          frequency: OneTime(),
          categories: {
            "jfaksdpofjasodf":
                MonetaryAmount(currency: "ETB", amount: 500 * 100),
            "jfasodifjasodjffasdasd":
                MonetaryAmount(currency: "ETB", amount: 500 * 100),
            "614193c7f2ea51b47f5896b9":
                MonetaryAmount(currency: "ETB", amount: 500 * 100)
          },
        ),
      ],
      categories: [
        Category(
          id: "fpoq3cum4cpu43241u34",
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          name: "Mental health",
          parentId: null,
          tags: ["health"],
        ),
        Category(
          id: "mucpxo2ur3p98u32proxi34",
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          name: "Atmosphere",
          parentId: "fpoq3cum4cpu43241u34",
          tags: [],
        ),
        Category(
          id: "614193c7f2ea51b47f5896b8",
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          name: "Medicine",
          parentId: null,
          tags: ["pharma"],
        ),
        Category(
          id: "614193c7f2ea51b47f5896b9",
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          name: "RejuvPill",
          parentId: "614193c7f2ea51b47f5896b8",
          tags: ["health", "pharma"],
        ),
        Category(
          id: "jfaksdpofjasodf",
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          name: "P's & Q's",
          parentId: null,
          tags: ["Id"],
        ),
        Category(
          id: "jfasodifjasodjffasdasd",
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          name: "And O's",
          parentId: "jfaksdpofjasodf",
          tags: ["Ego"],
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
          amount: MonetaryAmount(currency: "ETB", amount: 400 * 100),
        ),
        Expense(
          id: "614193c7f2ea51b47f5896bd",
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          name: "Xanax purchase",
          categoryId: "614193c7f2ea51b47f5896b8",
          budgetId: "614193c7f2ea51b47f5896ba",
          amount: MonetaryAmount(currency: "ETB", amount: 200 * 100),
        ),
        Expense(
          id: "um3p24urpoi23u4crp23iuj4xp",
          createdAt: now.add(Duration(days: -1)),
          updatedAt: now.add(Duration(days: -1)),
          name: "Flower Blood incense",
          categoryId: "mucpxo2ur3p98u32proxi34",
          budgetId: "614193c7f2ea51b47f5896ba",
          amount: MonetaryAmount(currency: "ETB", amount: 50 * 100),
        ),
        Expense(
          id: "j2cpiojr2p3io4jrc92p34jr234r",
          createdAt: now.add(Duration(days: -40)),
          updatedAt: now.add(Duration(days: -40)),
          name: "Switchblade puchase",
          categoryId: "fpoq3cum4cpu43241u34",
          budgetId: "614193c7f2ea51b47f5896ba",
          amount: MonetaryAmount(currency: "ETB", amount: 100 * 100),
        ),
        Expense(
          id: "rcjp2i3ou4cr23oi4jrc324c23w",
          createdAt: now.add(Duration(days: -400)),
          updatedAt: now.add(Duration(days: -400)),
          name: "Private eye hire",
          categoryId: "fpoq3cum4cpu43241u34",
          budgetId: "614193c7f2ea51b47f5896ba",
          amount: MonetaryAmount(currency: "ETB", amount: 300 * 100),
        ),
        Expense(
          id: "x1u423rxip3h42c9",
          createdAt: now.add(Duration(days: -400)),
          updatedAt: now.add(Duration(days: -400)),
          name: "Mia Culpa Groceries",
          categoryId: "jfasodifjasodjffasdasd",
          budgetId: "614193c7f2ea51b47f5896bb",
          amount: MonetaryAmount(currency: "ETB", amount: 300 * 100),
        ),
      ],
    );
  })();
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
        providers: [
          RepositoryProvider(
              create: (context) =>
                  UserRepository()..setItem(defaultUser.id, defaultUser)),
          RepositoryProvider(create: (context) {
            var repo = BudgetRepository();
            for (var item in defaultUser.budgets) {
              repo.setItem(item.id, item);
            }
            return repo;
          }),
          RepositoryProvider(create: (context) {
            var repo = CategoryRepository();
            for (var item in defaultUser.categories) {
              repo.setItem(item.id, item);
            }
            return repo;
          }),
          RepositoryProvider(create: (context) {
            var repo = ExpenseRepository();
            for (var item in defaultUser.expenses) {
              repo.setItem(item.id, item);
            }
            return repo;
          }),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => UserBloc(defaultUser)),
            BlocProvider(
              create: (context) => BudgetsBloc(context.read<BudgetRepository>())
                ..add(LoadBudgets()),
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
              onGenerateRoute: Routes.myOnGenerateRoute,
              // initialRoute: CategoryListPage.routeName,
              home: SmuniHomeScreen()),
        ),
      );
}
