import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/blocs/budget_list_page.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/widgets/budget_selector.dart';

import 'Budget/budgets_list_screen.dart';
import 'Expense/expense_list_page.dart';
import 'Budget/budget_detail_page.dart';
import 'Category/category_list_page.dart';
import 'settings_page.dart';

class SmuniHomeScreen extends StatefulWidget {
  SmuniHomeScreen({Key? key}) : super(key: key);

  static const String routeName = '/homeScreen';

  static Route route() {
    return MaterialPageRoute(
        builder: (context) => SmuniHomeScreen(),
        settings: RouteSettings(name: routeName));
  }

  @override
  State<SmuniHomeScreen> createState() => _SmuniHomeScreenState();
}

class _SmuniHomeScreenState extends State<SmuniHomeScreen> {
  int _selectedPage = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            [
              Icons.account_circle_sharp,
              Icons.account_circle_outlined,
              "Profile"
            ],
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
            return SettingsPage();
          case 3:
            return CategoryListPage.page();
          case 2:
            return ExpenseListPage.page();
          case 1:
            return BudgetListPage();
          case 0:
          default:
            return _homePage();
        }
      }),
    );
  }

  Widget _homePage() =>
      BlocBuilder<UserBloc, UserBlocState>(builder: (context, state) {
        if (state is UserLoadSuccess) {
          if (state.item.mainBudget != null) {
            return BudgetDetailsPage.page(state.item.mainBudget!);
          } else {
            return _mainBudgetSelector(context, state);
          }
        } else if (state is UserLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        throw Exception("unexpected state");
      });

  Widget _mainBudgetSelector(BuildContext context, UserLoadSuccess state) =>
      Scaffold(
          appBar: AppBar(
            title: Text('Home'),
          ),
          body: Center(
            child: Form(
              child: Column(
                children: [
                  Text("Main budget not selected:"),
                  ElevatedButton(
                    onPressed: () {
                      final selectorKey = GlobalKey<FormFieldState<String>>();
                      var budgetId = "";
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => StatefulBuilder(
                          builder: (builder, setState) => Column(children: [
                            BlocProvider(
                              create: (context) => BudgetListPageBloc(
                                  context.read<BudgetRepository>()),
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.4,
                                child: BudgetFormSelector(
                                  key: selectorKey,
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
                                onPressed: budgetId.isNotEmpty
                                    ? () {
                                        final selector =
                                            selectorKey.currentState;
                                        if (selector != null &&
                                            selector.validate()) {
                                          selector.save();
                                          context.read<UserBloc>().add(
                                                UpdateUser(User.from(state.item,
                                                    mainBudget: budgetId)),
                                              );
                                          Navigator.pop(context);
                                        }
                                      }
                                    : null,
                                child: const Text("Save Selection"))
                          ]),
                        ),
                      );
                    },
                    child: const Text("Select Main Budget"),
                  )
                ],
              ),
            ),
          ));
}

class HorizontalCards extends StatelessWidget {
  HorizontalCards({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        shadowColor: Colors.green,
        elevation: 3,
        child: SizedBox(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 8, 100, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CBE Wallet',
                  style: TextStyle(fontWeight: FontWeight.w400),
                ),
                SizedBox(
                  height: 8,
                ),
                Text(
                  '12,900 Br',
                  textScaleFactor: 1.6,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 5,
                ),
                Text(
                  'spent 5,000 Birr',
                  style: TextStyle(fontWeight: FontWeight.w300),
                )
                //Text('Spent 5000birr'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
