import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smuni/repositories/category.dart';
import 'package:smuni_api_client/smuni_api_client.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'bloc_observer.dart';
import 'blocs/blocs.dart';
import 'blocs/refresh.dart';
import 'constants.dart';
import 'models/models.dart';
import 'providers/cache/cache.dart';
import 'repositories/repositories.dart';
import 'screens/home_screen.dart';
import 'screens/routes.dart';
import 'utilities.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  MyApp({
    Key? key,
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<Pair<sqflite.Database, AuthTokenRepository>> _initAsyncFuture;
  final _client =
      SmuniApiClient("https://smuni-rest-api-staging.herokuapp.com");

  Future<Pair<sqflite.Database, AuthTokenRepository>> _initAsync() async {
    var databasesPath = await sqflite.getDatabasesPath();
    final path = databasesPath + "main.db";

    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}

    final db = await sqflite.openDatabase(
      sqflite.inMemoryDatabasePath,
      // path,
      version: 1,
      onCreate: (db, version) => db.transaction((txn) async {
        await migrateV1(txn);
        /* await SqliteUserCache(db)
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
        } */
      }),
    );

    final response = await _client.signInEmail(defaultUser.email!, "password");

    await SqliteUserCache(db)
        .setItem(response.user.username, User.from(response.user));
    {
      final cache = SqliteBudgetCache(db);
      for (final item in response.user.budgets) {
        await cache.setItem(item.id, item);
      }
    }
    {
      final cache = SqliteCategoryCache(db);
      for (final item in response.user.categories) {
        await cache.setItem(item.id, item);
      }
    }
    {
      final cache = SqliteExpenseCache(db);
      for (final item in response.user.expenses) {
        await cache.setItem(item.id, item);
      }
    }

    return Pair(
      db,
      await AuthTokenRepository.fromValues(
        client: _client,
        cache: AuthTokenCache(db),
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        loggedInUsername: defaultUser.username,
      ),
    );

    /* return Pair(
      db,
      FakeAuthTokenRepository(
          client: _client,
          cache: AuthTokenCache(db),
          username: defaultUser.username,
          accessToken: 'supersunday',
          refreshToken: 'imightgetafadedin2014'),
    ); */
  }

  @override
  void initState() {
    _initAsyncFuture = _initAsync();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => RepositoryProvider.value(
        value: _client,
        child: Builder(
            builder: (context) => FutureBuilder(
                  future: _initAsyncFuture,
                  builder: (context,
                      AsyncSnapshot<Pair<sqflite.Database, AuthTokenRepository>>
                          snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return Center(
                        child: Column(
                          children: const [
                            CircularProgressIndicator(),
                            // Text("Accessing db..."),
                          ],
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      throw snapshot.error!;
                    }
                    final db = snapshot.data!.a;
                    return MultiRepositoryProvider(
                      providers: [
                        RepositoryProvider.value(value: snapshot.data!.b),
                        RepositoryProvider(
                          create: (context) => UserRepository(
                            SqliteUserCache(db),
                            context.read<SmuniApiClient>(),
                            context.read<AuthTokenRepository>(),
                          ),
                        ),
                        RepositoryProvider(
                          create: (context) => BudgetRepository(
                            SqliteBudgetCache(db),
                            context.read<SmuniApiClient>(),
                            context.read<AuthTokenRepository>(),
                          ),
                        ),
                        RepositoryProvider(
                          create: (context) => CategoryRepository(
                            ApiCategoryRepository(
                              SqliteCategoryCache(db),
                              context.read<SmuniApiClient>(),
                              context.read<AuthTokenRepository>(),
                            ),
                          ),
                        ),
                        RepositoryProvider(
                          create: (context) => ExpenseRepository(
                            SqliteExpenseCache(db),
                            context.read<SmuniApiClient>(),
                            context.read<AuthTokenRepository>(),
                          ),
                        ),
                        RepositoryProvider(
                          create: (context) => CacheRefresher(
                            context.read<SmuniApiClient>(),
                            context.read<AuthTokenRepository>(),
                            userRepo: context.read<UserRepository>(),
                            budgetRepo: context.read<BudgetRepository>(),
                            categoryRepo: context.read<CategoryRepository>(),
                            expenseRepo: context.read<ExpenseRepository>(),
                          ),
                        ),
                        /* RepositoryProvider(
                          create: (context) => CacheRefresher(
                              context.read<SmuniApiClient>(),
                              SqliteExpenseCache(db)),
                        ), */
                      ],
                      child: MultiBlocProvider(
                        providers: [
                          BlocProvider(
                            create: (context) => UserBloc(
                                context.read<UserRepository>(), defaultUser.id),
                          ),
                          BlocProvider(
                            create: (context) {
                              var blocErrorBloc = BlocErrorBloc();
                              Bloc.observer = SimpleBlocObserver(blocErrorBloc);
                              return blocErrorBloc;
                            },
                          ),
                          BlocProvider(
                            create: (context) =>
                                RefresherBloc(context.read<CacheRefresher>()),
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
                              buttonTheme: ButtonThemeData(
                                textTheme: ButtonTextTheme.primary,
                              ),
                            ),
                            onGenerateRoute: Routes.myOnGenerateRoute,
                            // initialRoute: CategoryListPage.routeName,
                            home: SmuniHomeScreen(),
                          );
                        }),
                      ),
                    );
                  },
                )),
      );
}

final UserDenorm defaultUser = UserDenorm(
  id: "614193c7f2ea51b47f5896be",
  username: "superkind",
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  email: "don@key.ote",
  firebaseId: "ABCDEF_123456_ABCDEF_123456_",
  phoneNumber: "+251900112233",
  pictureURL: "https://imagine.co/9q6roh3cifnp",
  mainBudget: "614193c7f2ea51b47f5896ba",
  budgets: [
    Budget(
      id: "614193c7f2ea51b47f5896ba",
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: "Monthly budget",
      startTime: DateTime.parse("2021-07-31T21:00:00.000Z"),
      endTime: DateTime.parse("2021-08-31T21:00:00.000Z"),
      allocatedAmount: MonetaryAmount(currency: "ETB", amount: 15000 * 100),
      frequency: Recurring(2592000),
      categoryAllocations: {
        "614193c7f2ea51b47f5896b8": 1000 * 100,
        "614193c7f2ea51b47f5896b9": 1500 * 100,
        "616966d7ff32b0373dd0ec2f": 3000 * 100,
        "616966cfff32b0373dd0ec2e": 1500 * 100
      },
    ),
    Budget(
      id: "614193c7f2ea51b47f5896bb",
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      archivedAt: DateTime.now(),
      name: "Special budget",
      startTime: DateTime.parse("2021-07-31T21:00:00.000Z"),
      endTime: DateTime.parse("2021-08-31T21:00:00.000Z"),
      allocatedAmount: MonetaryAmount(currency: "ETB", amount: 2000 * 100),
      frequency: OneTime(),
      categoryAllocations: {
        "616966bcff32b0373dd0ec2c": 500 * 100,
        "616966c8ff32b0373dd0ec2d": 500 * 100,
        "616966cfff32b0373dd0ec2e": 500 * 100
      },
    ),
  ],
  categories: [
    Category(
      id: "616966d7ff32b0373dd0ec2f",
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: "Mental health",
      parentId: null,
      tags: ["health"],
    ),
    Category(
      id: "616966cfff32b0373dd0ec2e",
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: "Atmosphere",
      parentId: "616966d7ff32b0373dd0ec2f",
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
      id: "616966c8ff32b0373dd0ec2d",
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: "P's & Q's",
      archivedAt: DateTime.now(),
      parentId: null,
      tags: ["Id"],
    ),
    Category(
      id: "616966bcff32b0373dd0ec2c",
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: "And O's",
      parentId: "616966c8ff32b0373dd0ec2d",
      tags: ["Ego"],
    ),
    Category(
      id: "w3ioeunvfnasdlkjfnalk",
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: "Kicks",
      parentId: null,
      tags: ["Footlocker"],
    ),
    Category(
      id: "dnfvoijwemkzopsiejrklasldk",
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: "Curry 3ZER0",
      parentId: "w3ioeunvfnasdlkjfnalk",
      tags: [""],
    ),
  ],
  expenses: [
    Expense(
      id: "614193c7f2ea51b47f5896bc",
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: "Pill purchase",
      timestamp: DateTime.now(),
      categoryId: "614193c7f2ea51b47f5896b9",
      budgetId: "614193c7f2ea51b47f5896ba",
      amount: MonetaryAmount(currency: "ETB", amount: 400 * 100),
    ),
    Expense(
      id: "614193c7f2ea51b47f5896bd",
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: "Xanax purchase",
      timestamp: DateTime.now(),
      categoryId: "614193c7f2ea51b47f5896b8",
      budgetId: "614193c7f2ea51b47f5896ba",
      amount: MonetaryAmount(currency: "ETB", amount: 200 * 100),
    ),
    Expense(
      id: "616966acff32b0373dd0ec2b",
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: "Flower Blood incense",
      timestamp: DateTime.now().add(Duration(days: -1)),
      categoryId: "616966cfff32b0373dd0ec2e",
      budgetId: "614193c7f2ea51b47f5896ba",
      amount: MonetaryAmount(currency: "ETB", amount: 50 * 100),
    ),
    Expense(
      id: "616966a4ff32b0373dd0ec2a",
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: "Switchblade purchase",
      timestamp: DateTime.now().add(Duration(days: -40)),
      categoryId: "616966d7ff32b0373dd0ec2f",
      budgetId: "614193c7f2ea51b47f5896ba",
      amount: MonetaryAmount(currency: "ETB", amount: 100 * 100),
    ),
    Expense(
      id: "61696683ff32b0373dd0ec28",
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: "Private eye hire",
      timestamp: DateTime.now().add(Duration(days: -900)),
      categoryId: "616966d7ff32b0373dd0ec2f",
      budgetId: "614193c7f2ea51b47f5896ba",
      amount: MonetaryAmount(currency: "ETB", amount: 300 * 100),
    ),
    Expense(
      id: "6169668bff32b0373dd0ec29",
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: "Mia Culpa Groceries",
      timestamp: DateTime.now().add(Duration(days: -400)),
      categoryId: "616966bcff32b0373dd0ec2c",
      budgetId: "614193c7f2ea51b47f5896bb",
      amount: MonetaryAmount(currency: "ETB", amount: 300 * 100),
    ),
    Expense(
      id: "x1u42jrxie3h82c0",
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: "Mikeee boi made it rain",
      timestamp: DateTime.now().add(Duration(days: -1200)),
      categoryId: "jfasqdiyjasodjffasdbsd",
      budgetId: "614193d7f2ea61b47f5896cb",
      amount: MonetaryAmount(currency: "ETB", amount: 5000 * 100),
    ),
    Expense(
      id: "x1u48jrxie3h82c0",
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: "The green G class",
      timestamp: DateTime(1975, 4),
      categoryId: "jfasqdeyjasodjffasdbsd",
      budgetId: "614193d7f2ez61b47f5896cb",
      amount: MonetaryAmount(currency: "ETB", amount: 1000000 * 100),
    ),
    Expense(
      id: "x1u48jqxie3h82c6",
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: "The black G class",
      timestamp: DateTime(1990, 10),
      categoryId: "jfasqdeyjasodjmfasdbsd",
      budgetId: "61419397f2ez61b47f5896cb",
      amount: MonetaryAmount(currency: "ETB", amount: 100100 * 100),
    ),
  ],
);
