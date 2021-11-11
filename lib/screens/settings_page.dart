import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/constants.dart';
import 'package:smuni/utilities.dart';

import '../constants.dart';

class MenusPage extends StatefulWidget {
  const MenusPage({Key? key}) : super(key: key);

  static const String routeName = '/settings';

  static Route route() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) => MenusPage(),
    );
  }

  @override
  State<MenusPage> createState() => _MenusPageState();
}

class _MenusPageState extends State<MenusPage> {
  var _awaitingOp = false;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          shadowColor: Colors.transparent,
          centerTitle: true,
          title: Text(
            'Kamasio',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          // crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DrawerButtons(
                buttonName: 'About Us',
                drawerButtonAction: () => showAboutDialog(
                  context: context,
                  applicationName: "Smuni",
                  applicationVersion: "0.0.1-alpha",
                  children: [Text("TODO")],
                ),
              ),
            ),
            !_awaitingOp
                ? ElevatedButton(
                    onPressed: () {
                      setState(() => _awaitingOp = true);
                      context.read<SyncBloc>().add(TrySync(
                            onSuccess: () {
                              setState(() => _awaitingOp = false);
                            },
                            onError: (err) {
                              setState(() => _awaitingOp = false);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: err is ConnectionException
                                      ? Text('Connection Failed')
                                      : err is ConnectionException
                                          ? Text('Not Signed In')
                                          : Text('Unknown Error Occured'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ));
                    },
                    child: const Text("Sync"),
                  )
                : const CircularProgressIndicator(),
            /* !_awaitingOp
                ? ElevatedButton(
                    onPressed: () async {
                      setState(() => _awaitingOp = true);
                      final s = context.read<CacheSynchronizer>();
                      final catA = await s.offlineCategoryRepo
                          .createItemOffline(CreateCategoryInput(
                        name: "A",
                      ));
                      final catB = await s.offlineCategoryRepo
                          .createItemOffline(CreateCategoryInput(
                              name: "B", parentId: catA.parentId));
                      final catC = await s.offlineCategoryRepo
                          .createItemOffline(CreateCategoryInput(
                              name: "C", parentId: catB.parentId));

                      final catD = await s.offlineCategoryRepo
                          .createItemOffline(CreateCategoryInput(
                        name: "C",
                      ));

                      final budA = await s.offlineBudgetRepo
                          .createItemOffline(CreateBudgetInput(
                        name: "A",
                        startTime: DateRange.monthRange(DateTime.now()).start,
                        endTime: DateRange.monthRange(DateTime.now()).end,
                        frequency: OneTime(),
                        allocatedAmount:
                            MonetaryAmount(amount: 100 * 100, currency: "ETB"),
                        categoryAllocations: {
                          catA.id: 50 * 100,
                          catD.id: 50 * 100,
                        },
                      ));

                      final expZ = await s.offlineExpenseRepo
                          .createItemOffline(CreateExpenseInput(
                        name: "Z",
                        amount:
                            MonetaryAmount(amount: 50 * 100, currency: "ETB"),
                        budgetId: budA.id,
                        categoryId: catA.id,
                      ));
                      final expX = await s.offlineExpenseRepo
                          .createItemOffline(CreateExpenseInput(
                        name: "X",
                        amount:
                            MonetaryAmount(amount: 40 * 100, currency: "ETB"),
                        budgetId: budA.id,
                        categoryId: catD.id,
                      ));
                      await s.offlineCategoryRepo.updateItemOffline(
                        catA.id,
                        UpdateCategoryInput(
                            lastSeenVersion: catA.version, archive: true),
                      );
                      setState(() => _awaitingOp = false);
                    },
                    child: const Text("Add Dummy Data"),
                  )
                : const CircularProgressIndicator(), */
          ],
        ),
      );
}

class DrawerButtons extends StatelessWidget {
  final String buttonName;
  final Function() drawerButtonAction;
  const DrawerButtons(
      {Key? key, required this.buttonName, required this.drawerButtonAction})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: drawerButtonAction,
        child: Text(
          buttonName,
          style: TextStyle(fontSize: 20),
        ),
        style: ElevatedButton.styleFrom(
            fixedSize: Size(250, 60),
            primary: Colors.transparent,
            shadowColor: Colors.transparent,
            onPrimary: semuni500,
            // padding: EdgeInsets.symmetric(vertical: 16, horizontal: 72),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            side: BorderSide(color: semuni500, width: 2)));
  }
}
