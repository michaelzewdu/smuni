import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smuni/screens/home_screen.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'bloc_observer.dart';
import 'blocs/blocs.dart';
import 'constants.dart';
import 'models/models.dart';
import 'repositories/repositories.dart';
import 'providers/cache/cache.dart';
import 'screens/routes.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({
    Key? key,
  }) : super(key: key);

  final UserDenorm defaultUser = (() {
    final now = DateTime.now();
    return UserDenorm(
      id: "614193c7f2ea51b47f5896be",
      username: "superkind",
      createdAt: now,
      updatedAt: now,
      email: "don@key.ote",
      firebaseId: "ABCDEF_123456_ABCDEF_123456_",
      phoneNumber: "+251900112233",
      pictureURL: "https://imagine.co/9q6roh3cifnp",
      budgets: [
        Budget(
          id: "614193c7f2ea51b47f5896ba",
          createdAt: now,
          updatedAt: now,
          name: "Monthly budget",
          startTime: DateTime.parse("2021-07-31T21:00:00.000Z"),
          endTime: DateTime.parse("2021-08-31T21:00:00.000Z"),
          allocatedAmount: MonetaryAmount(currency: "ETB", amount: 7000 * 100),
          frequency: Recurring(2592000),
          categoryAllocations: {
            "fpoq3cum4cpu43241u34": 1000 * 100,
            "mucpxo2ur3p98u32proxi34": 300 * 100,
            "614193c7f2ea51b47f5896b8": 1000 * 100,
            "614193c7f2ea51b47f5896b9": 500 * 100
          },
        ),
        Budget(
          id: "614193c7f2ea51b47f5896bb",
          createdAt: now,
          updatedAt: now,
          name: "Special budget",
          startTime: DateTime.parse("2021-07-31T21:00:00.000Z"),
          endTime: DateTime.parse("2021-08-31T21:00:00.000Z"),
          allocatedAmount: MonetaryAmount(currency: "ETB", amount: 2000 * 100),
          frequency: OneTime(),
          categoryAllocations: {
            "jfaksdpofjasodf": 500 * 100,
            "jfasodifjasodjffasdasd": 500 * 100,
            "614193c7f2ea51b47f5896b9": 500 * 100
          },
        ),
      ],
      categories: [
        Category(
          id: "fpoq3cum4cpu43241u34",
          createdAt: now,
          updatedAt: now,
          name: "Mental health",
          parentId: null,
          tags: ["health"],
        ),
        Category(
          id: "mucpxo2ur3p98u32proxi34",
          createdAt: now,
          updatedAt: now,
          name: "Atmosphere",
          parentId: "fpoq3cum4cpu43241u34",
          tags: [],
        ),
        Category(
          id: "614193c7f2ea51b47f5896b8",
          createdAt: now,
          updatedAt: now,
          name: "Medicine",
          parentId: null,
          tags: ["pharma"],
        ),
        Category(
          id: "614193c7f2ea51b47f5896b9",
          createdAt: now,
          updatedAt: now,
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
          createdAt: now,
          updatedAt: now,
          name: "And O's",
          parentId: "jfaksdpofjasodf",
          tags: ["Ego"],
        ),
      ],
      expenses: [
        Expense(
          id: "614193c7f2ea51b47f5896bc",
          createdAt: now,
          updatedAt: now,
          name: "Pill purchase",
          categoryId: "614193c7f2ea51b47f5896b9",
          budgetId: "614193c7f2ea51b47f5896ba",
          amount: MonetaryAmount(currency: "ETB", amount: 400 * 100),
        ),
        Expense(
          id: "614193c7f2ea51b47f5896bd",
          createdAt: now,
          updatedAt: now,
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
          createdAt: now.add(Duration(days: -900)),
          updatedAt: now.add(Duration(days: -900)),
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
        Expense(
          id: "x1u42jrxie3h82c0",
          createdAt: now.add(Duration(days: -1200)),
          updatedAt: now.add(Duration(days: -1200)),
          name: "Mikeee boi made it rain",
          categoryId: "jfasqdiyjasodjffasdbsd",
          budgetId: "614193d7f2ea61b47f5896cb",
          amount: MonetaryAmount(currency: "ETB", amount: 5000 * 100),
        ),
        Expense(
          id: "x1u48jrxie3h82c0",
          createdAt: DateTime(1975, 4),
          updatedAt: DateTime(1975, 4),
          name: "The green G class",
          categoryId: "jfasqdeyjasodjffasdbsd",
          budgetId: "614193d7f2ez61b47f5896cb",
          amount: MonetaryAmount(currency: "ETB", amount: 1000000 * 100),
        ),
        Expense(
          id: "x1u48jqxie3h82c6",
          createdAt: DateTime(1990, 10),
          updatedAt: DateTime(1990, 10),
          name: "The black G class",
          categoryId: "jfasqdeyjasodjmfasdbsd",
          budgetId: "61419397f2ez61b47f5896cb",
          amount: MonetaryAmount(currency: "ETB", amount: 100100 * 100),
        ),
      ],
    );
  })();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: () async {
          var databasesPath = await sqflite.getDatabasesPath();
          final path = databasesPath + "main.db";
          return await sqflite.openDatabase(
            // sqflite.inMemoryDatabasePath,
            path,
            version: 1,
            onCreate: (db, version) => db.transaction((txn) async {
              await migrateV1(txn);
              await SqliteUserCache(db)
                  .setItem(defaultUser.id, User.from(defaultUser));
              {
                final cache = SqliteBudgetCache(db);
                for (var item in defaultUser.budgets) {
                  await cache.setItem(item.id, item);
                }
              }
              {
                final cache = SqliteCategoryCache(db);
                for (var item in defaultUser.categories) {
                  await cache.setItem(item.id, item);
                }
              }
              {
                final cache = SqliteExpenseCache(db);
                for (var item in defaultUser.expenses) {
                  await cache.setItem(item.id, item);
                }
              }
            }),
          );
        }(),
        builder: (context, AsyncSnapshot<sqflite.Database> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            throw snapshot.error!;
          }
          final db = snapshot.data!;
          return MultiRepositoryProvider(
            providers: [
              /* RepositoryProvider(
                create: (context) => AuthTokenRepository.fromCache(client, AuthTokenCache(db)),
              ), */
              RepositoryProvider(
                create: (context) => UserRepository(SqliteUserCache(db)),
              ),
              RepositoryProvider(
                create: (context) => BudgetRepository(SqliteBudgetCache(db)),
              ),
              RepositoryProvider(
                create: (context) =>
                    CategoryRepository(SqliteCategoryCache(db)),
              ),
              RepositoryProvider(
                create: (context) => ExpenseRepository(SqliteExpenseCache(db)),
              ),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (context) =>
                      UserBloc(context.read<UserRepository>(), defaultUser.id),
                ),
                BlocProvider(
                  create: (context) {
                    var blocErrorBloc = BlocErrorBloc();
                    Bloc.observer = SimpleBlocObserver(blocErrorBloc);
                    return blocErrorBloc;
                  },
                ),
              ],
              child: BlocBuilder<BlocErrorBloc, BlocErrorBlocState>(
                  builder: (context, state) {
                if (state is ErrorObserved) throw state.error;

                return MaterialApp(
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
                  theme: ThemeData(
                    primarySwatch: primarySmuniSwatch,
                    buttonTheme:
                        ButtonThemeData(textTheme: ButtonTextTheme.primary),
                  ),
                  onGenerateRoute: Routes.myOnGenerateRoute,
                  // initialRoute: CategoryListPage.routeName,
                  home: SmuniHomeScreen(),
                );
              }),
            ),
          );
        },
      );
}
