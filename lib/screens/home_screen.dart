import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/blocs/budget_list_page.dart';
import 'package:smuni/blocs/refresh.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni/widgets/budget_selector.dart';

import 'Budget/budget_details_page.dart';
import 'Budget/budget_list_page.dart';
import 'Category/category_list_page.dart';
import 'Expense/expense_list_page.dart';
import 'settings_page.dart';

class SmuniHomeScreen extends StatefulWidget {
  SmuniHomeScreen({Key? key}) : super(key: key);

  static const String routeName = '/';

  static Route route() => MaterialPageRoute(
        builder: (context) => SmuniHomeScreen(),
        settings: RouteSettings(name: routeName),
      );

  @override
  State<SmuniHomeScreen> createState() => _SmuniHomeScreenState();
}

class _SmuniHomeScreenState extends State<SmuniHomeScreen> {
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RefresherBloc, RefresherBlocState>(
        builder: (context, state) =>
            state is Refreshed ? DefaultHomeScreen() : RefreshScreen(),
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

  Widget _homePage() =>
      BlocBuilder<UserBloc, UserBlocState>(builder: (context, userState) {
        if (userState is UserLoadSuccess) {
          if (userState.item.mainBudget != null) {
            return BudgetDetailsPage.page(
              userState.item.mainBudget!,
              (context, state) => [
                ElevatedButton(
                  onPressed: () =>
                      _showMainBudgetSelectorModal(context, userState),
                  child: const Text("Change"),
                ),
              ],
            );
          } else {
            return Scaffold(
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
                          onPressed: () =>
                              _showMainBudgetSelectorModal(context, userState),
                          child: const Text("Select Main Budget"),
                        )
                      ],
                    ),
                  ),
                ));
          }
        } else if (userState is UserLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        throw Exception("unexpected state");
      });

  void _showMainBudgetSelectorModal(
    BuildContext context,
    UserLoadSuccess state,
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
                    create: (context) =>
                        BudgetListPageBloc(context.read<BudgetRepository>()),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: BudgetFormSelector(
                        key: selectorKey,
                        isSelecting: true,
                        onChanged: (value) {
                          setState(() {
                            budgetId = value!;
                          });
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
                              context.read<UserBloc>().add(
                                    UpdateUser(
                                      User.from(state.item,
                                          mainBudget: budgetId),
                                      onSuccess: () {
                                        setState(() => awaitingOp = false);
                                        this.setState(() => {});
                                        Navigator.pop(context);
                                      },
                                      onError: (err) {
                                        setState(() => awaitingOp = false);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: err is ConnectionException
                                                ? Text('Connection Failed')
                                                : Text('Unknown Error Occured'),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                    ),
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

class RefreshScreen extends StatefulWidget {
  const RefreshScreen({Key? key}) : super(key: key);

  @override
  State<RefreshScreen> createState() => _RefreshScreenState();
}

class _RefreshScreenState extends State<RefreshScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(context) => BlocConsumer<RefresherBloc, RefresherBlocState>(
        listener: (context, state) {
          if (state is Refreshed) {
            Navigator.pushReplacementNamed(
              context,
              SmuniHomeScreen.routeName,
            );
          }
        },
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text("Kamasio")),
          body: Center(
            child: state is RefreshFailed
                ? Column(
                    children: [
                      state.exception.inner is ConnectionException
                          ? Text("Refresh failed: connection error")
                          : Text("Refresh failed: unhandled error"),
                      const Text("Please try again"),
                      ElevatedButton(
                        onPressed: () =>
                            context.read<RefresherBloc>().add(Refresh()),
                        child: const Text("Refresh"),
                      )
                    ],
                  )
                : state is Refreshing
                    ? Column(children: const [
                        Text("Loading..."),
                        CircularProgressIndicator()
                      ])
                    : const CircularProgressIndicator(),
          ),
        ),
      );
}
