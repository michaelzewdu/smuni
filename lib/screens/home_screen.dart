import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/blocs/budget_list_page.dart';
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
                        Text("Main budget not selected:"),
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
          body: Column(children: [
            ElevatedButton(
              onPressed: !awaitingOp && budgetId.isNotEmpty
                  ? () {
                      final selector = selectorKey.currentState;
                      if (selector != null && selector.validate()) {
                        selector.save();
                        context.read<UserBloc>().add(
                              UpdateUser(
                                User.from(state.item, mainBudget: budgetId),
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
                              ),
                            );
                        ;
                        setState(() => awaitingOp = true);
                      }
                    }
                  : null,
              child: awaitingOp
                  ? const CircularProgressIndicator()
                  : const Text("Save Selection"),
            ),
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
          ]),
        ),
      ),
    );
  }
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
