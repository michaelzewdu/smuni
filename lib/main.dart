import 'package:bloc/bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smuni/screens/auth/sign_in_page.dart';
import 'package:smuni_api_client/smuni_api_client.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'bloc_observer.dart';
import 'blocs/blocs.dart';
import 'blocs/signup.dart';
import 'constants.dart';
import 'models/models.dart';
import 'providers/cache/cache.dart';
import 'repositories/repositories.dart';
import 'screens/home_screen.dart';
import 'screens/routes.dart';
import 'screens/splash.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({
    Key? key,
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _client =
      SmuniApiClient("https://smuni-rest-api-staging.herokuapp.com");
  late Future<sqflite.Database> _initAsyncFuture;

  @override
  void initState() {
    _initAsyncFuture = () async {
      await Firebase.initializeApp();
      return await initDb();
    }();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => RepositoryProvider.value(
        value: _client,
        child: FutureBuilder(
            future: _initAsyncFuture,
            builder: (
              context,
              AsyncSnapshot<sqflite.Database> snapshot,
            ) {
              if (snapshot.connectionState != ConnectionState.done) {
                return MaterialApp(home: SplashPage());
              }
              if (snapshot.hasError) {
                throw snapshot.error!;
              }
              final db = snapshot.data!;
              return MultiRepositoryProvider(
                providers: [
                  RepositoryProvider(create: (context) => SqliteUserCache(db)),
                  RepositoryProvider(
                    create: (context) => SqliteBudgetCache(db),
                  ),
                  RepositoryProvider(
                    create: (context) =>
                        ServerVersionSqliteCache(SqliteBudgetCache(db)),
                  ),
                  RepositoryProvider(
                    create: (context) => SqliteRemovedBudgetsCache(db),
                  ),
                  RepositoryProvider(
                    create: (context) => SqliteCategoryCache(db),
                  ),
                  RepositoryProvider(
                    create: (context) =>
                        ServerVersionSqliteCache(SqliteCategoryCache(db)),
                  ),
                  RepositoryProvider(
                    create: (context) => SqliteRemovedCategoriesCache(db),
                  ),
                  RepositoryProvider(
                    create: (context) => SqliteExpenseCache(db),
                  ),
                  RepositoryProvider(
                    create: (context) =>
                        ServerVersionSqliteCache(SqliteExpenseCache(db)),
                  ),
                  RepositoryProvider(
                    create: (context) => SqliteRemovedExpensesCache(db),
                  ),
                  RepositoryProvider(
                    create: (context) => SqliteIncomeCache(db),
                  ),
                  RepositoryProvider(
                    create: (context) =>
                        ServerVersionSqliteCache(SqliteIncomeCache(db)),
                  ),
                  RepositoryProvider(
                    create: (context) => SqliteRemovedIncomesCache(db),
                  ),
                  RepositoryProvider(create: (context) => PreferencesCache(db)),
                  RepositoryProvider(create: (context) => AuthTokenCache(db)),
                  RepositoryProvider(
                    create: (context) => AuthRepository(
                      context.read<SmuniApiClient>(),
                      context.read<AuthTokenCache>(),
                    ),
                  ),
                  RepositoryProvider(
                    create: (context) => UserRepository(
                      context.read<SqliteUserCache>(),
                      context.read<SmuniApiClient>(),
                    ),
                  ),
                ],
                child: MultiRepositoryProvider(
                  providers: [
                    RepositoryProvider(
                      create: (context) => UserRepository(
                        context.read<SqliteUserCache>(),
                        context.read<SmuniApiClient>(),
                      ),
                    ),
                    RepositoryProvider(
                      create: (context) => BudgetRepository(
                        context.read<SmuniApiClient>(),
                        context.read<SqliteBudgetCache>(),
                      ),
                    ),
                    RepositoryProvider(
                      create: (context) => OfflineBudgetRepository(
                        context.read<SqliteBudgetCache>(),
                        context
                            .read<ServerVersionSqliteCache<String, Budget>>(),
                        context.read<SqliteRemovedBudgetsCache>(),
                      ),
                    ),
                    RepositoryProvider(
                      create: (context) => CategoryRepository(
                        context.read<SqliteCategoryCache>(),
                        context.read<SmuniApiClient>(),
                      ),
                    ),
                    RepositoryProvider(
                      create: (context) => OfflineCategoryRepository(
                        context.read<SqliteCategoryCache>(),
                        context
                            .read<ServerVersionSqliteCache<String, Category>>(),
                        context.read<SqliteRemovedCategoriesCache>(),
                      ),
                    ),
                    RepositoryProvider(
                      create: (context) => ExpenseRepository(
                        context.read<SqliteExpenseCache>(),
                        context.read<SmuniApiClient>(),
                      ),
                    ),
                    RepositoryProvider(
                      create: (context) => OfflineExpenseRepository(
                        context.read<SqliteExpenseCache>(),
                        context
                            .read<ServerVersionSqliteCache<String, Expense>>(),
                        context.read<SqliteRemovedExpensesCache>(),
                      ),
                    ),
                    RepositoryProvider(
                      create: (context) => IncomeRepository(
                        context.read<SqliteIncomeCache>(),
                        context.read<SmuniApiClient>(),
                      ),
                    ),
                    RepositoryProvider(
                      create: (context) => OfflineIncomeRepository(
                        context.read<SqliteIncomeCache>(),
                        context
                            .read<ServerVersionSqliteCache<String, Income>>(),
                        context.read<SqliteRemovedIncomesCache>(),
                      ),
                    ),
                    RepositoryProvider(
                      create: (context) => CacheSynchronizer(
                        context.read<SmuniApiClient>(),
                        userRepo: context.read<UserRepository>(),
                        budgetRepo: context.read<BudgetRepository>(),
                        categoryRepo: context.read<CategoryRepository>(),
                        expenseRepo: context.read<ExpenseRepository>(),
                        incomeRepo: context.read<IncomeRepository>(),
                        offlineBudgetRepo:
                            context.read<OfflineBudgetRepository>(),
                        offlineCategoryRepo:
                            context.read<OfflineCategoryRepository>(),
                        offlineExpenseRepo:
                            context.read<OfflineExpenseRepository>(),
                        offlineIncomeRepo:
                            context.read<OfflineIncomeRepository>(),
                      ),
                    ),
                  ],
                  child: MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (context) => AuthBloc(
                            context.read<AuthRepository>(),
                            context.read<CacheSynchronizer>(),
                            context.read<PreferencesCache>())
                          ..add(CheckCache()),
                      ),
                      BlocProvider(
                        create: (context) => PreferencesBloc(
                          context.read<PreferencesCache>(),
                          context.read<AuthBloc>(),
                          context.read<UserRepository>(),
                          context.read<CacheSynchronizer>(),
                        )..add(LoadPreferences()),
                      ),
                      BlocProvider(
                        create: (context) => SignUpBloc(
                          context.read<AuthRepository>(),
                          NotSignedUp(),
                        ),
                      ),
                      BlocProvider(
                        create: (context) => UserBloc(
                          context.read<UserRepository>(),
                          context.read<AuthBloc>(),
                        ),
                      ),
                      BlocProvider(
                        create: (context) => SyncBloc(
                          context.read<CacheSynchronizer>(),
                          context.read<AuthBloc>(),
                          context.read<PreferencesBloc>(),
                        ),
                      ),
                    ],
                    child: BlocProvider(
                      create: (context) {
                        var blocErrorBloc = BlocErrorBloc();
                        Bloc.observer = SimpleBlocObserver(blocErrorBloc);
                        return blocErrorBloc;
                      },
                      child: BlocBuilder<BlocErrorBloc, BlocErrorBlocState>(
                        builder: (context, state) {
                          if (state is ErrorObserved) {
                            print(state.stackTrace);
                            throw state.error;
                          }
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
                              appBarTheme: AppBarTheme(
                                backgroundColor: semuni50,
                                foregroundColor: Colors.black,
                              ),
                              primarySwatch: primarySmuniSwatch,
                              buttonTheme: ButtonThemeData(
                                textTheme: ButtonTextTheme.primary,
                              ),
                              floatingActionButtonTheme:
                                  FloatingActionButtonThemeData(
                                extendedTextStyle: TextStyle(),
                              ),
                            ),
                            onGenerateRoute: Routes.myOnGenerateRoute,
                            // initialRoute: CategoryListPage.routeName,
                            home: MultiBlocListener(
                              listeners: [
                                BlocListener<AuthBloc, AuthBlocState>(
                                  listener: (context, state) {
                                    if (state is AuthSuccess) {
                                      Navigator.pushReplacementNamed(
                                        context,
                                        SmuniHomeScreen.routeName,
                                      );
                                    } else if (state is Unauthenticated) {
                                      Navigator.pushReplacementNamed(
                                        context,
                                        SignInPage.routeName,
                                      );
                                    }
                                  },
                                ),
                                BlocListener<PreferencesBloc,
                                    PreferencesBlocState>(
                                  listener: (context, state) {
                                    if (state is PreferencesLoadSuccess) {
                                      context
                                          .read<SyncBloc>()
                                          .add(LoadSyncState());
                                    }
                                  },
                                ),
                              ],
                              child: Scaffold(body: SplashPage()),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            }),
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
  miscCategory: "000000000000000000000000",
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
      id: "000000000000000000000000",
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: "Misc",
      parentId: null,
      tags: ["misc"],
    ),
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
  incomes: [
    Income(
      id: "6169668bff32b0373dd0ec29",
      createdAt: DateTime.now().add(Duration(days: -1)),
      updatedAt: DateTime.now().add(Duration(days: -1)),
      name: "Salary",
      timestamp: DateTime.now().add(Duration(days: -1)),
      frequency: Recurring(1 * 30 * 24 * 60 * 60),
      amount: MonetaryAmount(currency: "ETB", amount: 14000 * 100),
    ),
    Income(
      id: "6169668bff32b0373dd0ec39",
      createdAt: DateTime.now().add(Duration(days: -7)),
      updatedAt: DateTime.now().add(Duration(days: -7)),
      name: "Cheque 1",
      timestamp: DateTime.now().add(Duration(days: -7)),
      frequency: OneTime(),
      amount: MonetaryAmount(currency: "ETB", amount: 50000 * 100),
    ),
    Income(
      id: "6169668bff32b0373dd0ec39",
      createdAt: DateTime.now().add(Duration(days: -3)),
      updatedAt: DateTime.now().add(Duration(days: -3)),
      name: "Cheque 2",
      timestamp: DateTime.now().add(Duration(days: -3)),
      frequency: OneTime(),
      amount: MonetaryAmount(currency: "ETB", amount: 25000 * 100),
    ),
  ],
);
