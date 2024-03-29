import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni/widgets/widgets.dart';

import 'Budget/budget_details_page.dart';
import 'Budget/budget_list_page.dart';
import 'Category/category_list_page.dart';
import 'Expense/expense_list_page.dart';
import 'income/income_list_page.dart';
import 'settings_page.dart';

class SmuniHomeScreen extends StatefulWidget {
  SmuniHomeScreen({Key? key}) : super(key: key);

  static const String routeName = '/home';

  static Route route() => MaterialPageRoute(
        settings: RouteSettings(name: routeName),
        builder: (context) => SmuniHomeScreen(),
      );

  @override
  State<SmuniHomeScreen> createState() => _SmuniHomeScreenState();
}

class _SmuniHomeScreenState extends State<SmuniHomeScreen> {
  @override
  Widget build(BuildContext context) => BlocBuilder<AuthBloc, AuthBlocState>(
        builder: (context, authState) => authState is AuthSuccess
            ? BlocBuilder<SyncBloc, SyncBlocState>(
                builder: (context, state) =>
                    state is Synced ? DefaultHomeScreen() : SyncScreen(),
              )
            : DefaultHomeScreen(),
      );
}

class DefaultHomeScreen extends StatefulWidget {
  DefaultHomeScreen({Key? key}) : super(key: key);

  @override
  _DefaultHomeScreenState createState() => _DefaultHomeScreenState();
}

class _DefaultHomeScreenState extends State<DefaultHomeScreen> {
  int _selectedPage = 0;

  @override
  Widget build(context) => Scaffold(
        bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedPage,
            onTap: (idx) => setState(() => _selectedPage = idx),
            items: const <List<dynamic>>[
              [Icons.home_outlined, Icons.home_filled, "Home"],
              [Icons.add_chart_outlined, Icons.add_chart, "Budgets"],
              [
                Icons.featured_play_list_outlined,
                Icons.featured_play_list_rounded,
                "Expenses"
              ],
              [
                Icons.align_horizontal_left_sharp,
                Icons.align_horizontal_center,
                "Categories"
              ],
              [Icons.wysiwyg_sharp, Icons.assignment, "Incomes"],
            ]
                .map((e) => BottomNavigationBarItem(
                      icon: Icon(e[0]),
                      label: e[2],
                      activeIcon: Icon(e[1]),
                    ))
                .toList()),
        body: Builder(builder: (context) {
          switch (_selectedPage) {
            case 4:
              return IncomeListPage.page();
            case 3:
              return CategoryListPage.page();
            case 2:
              return ExpenseListPage.page();
            case 1:
              return BudgetListPage.page();
            case 0:
            default:
              return _homePage();
          }
        }),
      );

  Widget _homePage() => BlocBuilder<AuthBloc, AuthBlocState>(
        builder: (context, authState) => authState is AuthSuccess
            ? BlocBuilder<PreferencesBloc, PreferencesBlocState>(
                builder: (context, prefState) =>
                    prefState is PreferencesLoadSuccess
                        ? _showHome(
                            prefState.preferences.mainBudget,
                            (newMainBudget, {onSuccess, onError}) =>
                                context.read<PreferencesBloc>().add(
                                      UpdatePreferences(
                                        Preferences.from(
                                          prefState.preferences,
                                          mainBudget: newMainBudget,
                                        ),
                                        onSuccess: () {
                                          onSuccess?.call();
                                          setState(() {});
                                        },
                                        onError: onError,
                                      ),
                                    ),
                          )
                        : prefState is PreferencesLoading
                            ? const Center(child: CircularProgressIndicator())
                            : throw Exception("unexpected state"),
              )
            : BlocBuilder<PreferencesBloc, PreferencesBlocState>(
                builder: (context, preferencesState) {
                  if (preferencesState is PreferencesLoadSuccess) {
                    print(
                        'Current preference state ${preferencesState.preferences.mainBudget}');
                    return _showHome(
                      preferencesState.preferences.mainBudget,
                      (newMainBudget, {onSuccess, onError}) =>
                          context.read<PreferencesBloc>().add(
                                UpdatePreferences(
                                  // preferencesState.preferences,
                                  Preferences.from(preferencesState.preferences,
                                      mainBudget: newMainBudget),
                                  onSuccess: onSuccess,
                                  onError: onError,
                                ),
                              ),
                    );
                  } else if (preferencesState is PreferencesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  throw Exception("unexpected state");
                },
              ),
      );

  Widget _showHome(
    String? mainBudget,
    void Function(
      String newMainBudget, {
      OperationSuccessNotifier? onSuccess,
      OperationExceptionNotifier? onError,
    })
        changeMainBudget,
  ) =>
      mainBudget != null
          ? BudgetDetailsPage.page(
              mainBudget,
              (context, state) => [
                TextButton(
                  onPressed: () =>
                      showMainBudgetSelectorModal(context, changeMainBudget),
                  child: const Text(
                    "Change",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, SettingsPage.routeName),
                  child: const Text("Settings",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            )
          : Scaffold(
              appBar: AppBar(
                title: Text('Home'),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, SettingsPage.routeName),
                    child: const Text("Settings"),
                  ),
                ],
              ),
              body: Center(
                child: Form(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("Main budget not selected:"),
                      ),
                      ElevatedButton(
                        onPressed: () => showMainBudgetSelectorModal(
                          context,
                          changeMainBudget,
                        ),
                        child: const Text("Select Main Budget"),
                      )
                    ],
                  ),
                ),
              ),
            );
}

class SyncScreen extends StatefulWidget {
  const SyncScreen({Key? key}) : super(key: key);

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(context) => BlocConsumer<SyncBloc, SyncBlocState>(
        listener: (context, state) {
          if (state is Synced) {
            Navigator.pushReplacementNamed(
              context,
              SmuniHomeScreen.routeName,
            );
          }
        },
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text("Kamasio")),
          body: state is DeSynced
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      state is SyncFailed
                          ? state.exception.inner is ConnectionException
                              ? Text("Sync failed: connection error")
                              : state.exception.inner
                                      is UnauthenticatedException
                                  ? Text("Sync failed: signed out")
                                  : Text("Sync failed: unhandled error")
                          : state is ReportedDesync
                              ? Text("Hard server desynchronization")
                              : Text("Hard server desynchronization"),
                      const Text("Please try again"),
                      ElevatedButton(
                        onPressed: () => context.read<SyncBloc>().add(Sync()),
                        child: const Text("Refresh"),
                      )
                    ],
                  ),
                )
              : state is Syncing
                  ? Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text("Loading..."),
                            CircularProgressIndicator()
                          ]),
                    )
                  : throw Exception("Unhandeled state: $state"),
        ),
      );
}
