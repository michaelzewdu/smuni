import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni/widgets/widgets.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

import 'Budget/budget_details_page.dart';
import 'Budget/budget_list_page.dart';
import 'Category/category_list_page.dart';
import 'Expense/expense_list_page.dart';
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
              [Icons.home_filled, Icons.home, "Home"],
              [Icons.add_chart_outlined, Icons.add_chart, "Budgets"],
              [
                Icons.playlist_add_check_sharp,
                Icons.playlist_add_check_rounded,
                "Expenses"
              ],
              [
                Icons.align_horizontal_left_sharp,
                Icons.align_horizontal_center,
                "Categories"
              ],
              [Icons.assignment, Icons.wysiwyg_sharp, "Menu"],
            ]
                .map((e) => BottomNavigationBarItem(
                      icon: Icon(e[0]),
                      label: e[2],
                      activeIcon: Icon(e[1]),
                    ))
                .toList()),
        body: Builder(builder: (context) {
          // return Center(child: Text("Shit"));
          switch (_selectedPage) {
            case 4:
              return MenusPage();
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
            ? BlocBuilder<UserBloc, UserBlocState>(
                builder: (context, userState) {
                  if (userState is UserLoadSuccess) {
                    return _showHome(
                      userState.item.mainBudget,
                      (newMainBudget, {onSuccess, onError}) =>
                          context.read<UserBloc>().add(
                                UpdateUser(
                                  User.from(
                                    userState.item,
                                    mainBudget: newMainBudget,
                                  ),
                                  onSuccess: onSuccess,
                                  onError: onError,
                                ),
                              ),
                    );
                  } else if (userState is UserLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  throw Exception("unexpected state");
                },
              )
            : BlocBuilder<PreferencesBloc, PreferencesBlocState>(
                builder: (context, preferencesState) {
                  if (preferencesState is PreferencesLoadSuccess) {
                    return _showHome(
                      preferencesState.preferences.mainBudget,
                      (newMainBudget, {onSuccess, onError}) =>
                          context.read<PreferencesBloc>().add(
                                UpdatePreferences(
                                  preferencesState.preferences,
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
                ElevatedButton(
                  onPressed: () =>
                      _showMainBudgetSelectorModal(context, changeMainBudget),
                  child: const Text("Change"),
                ),
              ],
            )
          : Scaffold(
              appBar: AppBar(
                title: Text('Home'),
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
                        onPressed: () => _showMainBudgetSelectorModal(
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

  void _showMainBudgetSelectorModal(
    BuildContext context,
    void Function(
      String newMainBudget, {
      OperationSuccessNotifier? onSuccess,
      OperationExceptionNotifier? onError,
    })
        changeMainBudget,
  ) {
    final selectorKey = GlobalKey<FormFieldState<String>>();
    var budgetId = "";
    var awaitingOp = false;
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (builder, setState) => Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BlocProvider(
                    create: (context) => BudgetListPageBloc(
                      context.read<BudgetRepository>(),
                      context.read<OfflineBudgetRepository>(),
                    ),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: BudgetFormSelector(
                        key: selectorKey,
                        isSelecting: true,
                        onChanged: (value) {
                          setState(() => budgetId = value!);
                        },
                        validator: (value) {
                          if (value == null) {
                            return "No budget selected";
                          }
                        },
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: !awaitingOp && budgetId.isNotEmpty
                        ? () {
                            final selector = selectorKey.currentState;
                            if (selector != null && selector.validate()) {
                              selector.save();
                              changeMainBudget(
                                budgetId,
                                onSuccess: () {
                                  setState(() => awaitingOp = false);
                                  this.setState(() => {});
                                  Navigator.pop(context);
                                },
                                onError: (err) {
                                  setState(() => awaitingOp = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: err is ConnectionException
                                          ? Text('Connection Failed')
                                          : Text('Unknown Error Occured'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              );
                              setState(() => awaitingOp = true);
                            }
                          }
                        : null,
                    child: awaitingOp
                        ? const CircularProgressIndicator()
                        : const Text("Save Selection"),
                  ),
                ]),
          ),
        ),
      ),
    );
  }
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
          body: Center(
            child: state is DeSynced
                ? Column(
                    children: [
                      state is SyncFailed
                          ? state.exception.inner is ConnectionException
                              ? Text("Sync failed: connection error")
                              : state.exception.inner
                                      is UnauthenticatedException
                                  ? Text("Sync failed: signed out")
                                  : Text("Sync failed: unhandled error")
                          : state is ReportedDesync
                              ? Text(
                                  "Hard server desynchronization: please refresh")
                              : Text(
                                  "Hard server desynchronization: please refresh"),
                      const Text("Please try again"),
                      ElevatedButton(
                        onPressed: () => context.read<SyncBloc>().add(Sync()),
                        child: const Text("Refresh"),
                      )
                    ],
                  )
                : state is Syncing
                    ? Column(children: const [
                        Text("Loading..."),
                        CircularProgressIndicator()
                      ])
                    : const CircularProgressIndicator(),
          ),
        ),
      );
}
