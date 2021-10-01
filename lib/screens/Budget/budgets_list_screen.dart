import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/constants.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/screens/Budget/budget_detail_page.dart';
import 'package:smuni/widgets/money_editor.dart';

class BudgetListPage extends StatefulWidget {
  const BudgetListPage({Key? key}) : super(key: key);

  static const String routeName = '/budgetListScreen';

  static Route route() {
    return MaterialPageRoute(
        settings: RouteSettings(name: routeName),
        builder: (context) => BudgetListPage());
  }

  @override
  _BudgetListPageState createState() => _BudgetListPageState();
}

DateTime? _startDate;
DateTime? _endDate;

class _BudgetListPageState extends State<BudgetListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budgets'),
      ),
      body: BlocConsumer<BudgetsBloc, BudgetsBlocState>(
          builder: (context, state) {
        if (state is BudgetsLoading) {
          return CupertinoActivityIndicator(
            animating: true,
            radius: 76,
          );
        }
        if (state is BudgetsLoadSuccess) {
          final keys = state.items.keys;
          return ListView.builder(
            itemCount: state.items.length,
            itemBuilder: (BuildContext context, int index) {
              final budgetItem = state.items[keys.elementAt(index)];
              return ListTile(
                title: Text(
                  '${budgetItem!.name}',
                  textScaleFactor: 1.5,
                ),
                trailing: Text(
                  '${budgetItem.allocatedAmount.amount} ${budgetItem.allocatedAmount.currency}',
                  textScaleFactor: 1.5,
                ),
                subtitle: Row(children: [
                  Text(
                      '${budgetItem.startTime.month} ${budgetItem.startTime.day} ${budgetItem.startTime.year}  '),
                  Text(
                      'to  ${budgetItem.endTime.month} ${budgetItem.endTime.day} ${budgetItem.endTime.year}')
                ]),
                onTap: () {
                  Navigator.pushNamed(context, BudgetDetailsPage.routeName,
                      arguments: budgetItem.id);
                },
              );
            },
          );
        } else {
          return Text('An error occurred. Try again in a bit.');
        }
      }, listener: (context, state) {
        //  print('');
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          String newBudgetName = '';
          int budgetAmount = 0;
          String currency = 'Birr';
          bool isOneTime = false;
          var amountWholes;
          var amountCents;
          String amount;
          showModalBottomSheet(
              context: context,
              builder: (context) {
                //final formKey = GlobalKey<FormState>();

                String recurringIntervals = 'Every Month';
                final TextEditingController startDateController =
                    TextEditingController();

                final TextEditingController endDateController =
                    TextEditingController();

                return Scaffold(
                  resizeToAvoidBottomInset: false,
                  body: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setModalState) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Add new budget',
                                  textScaleFactor: 2,
                                  style: TextStyle(color: semuni500)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextFormField(
                                onChanged: (newText) {
                                  setState(() {
                                    newBudgetName = newText;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Name can't be empty";
                                  }
                                },
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(8))),
                                    hintText: 'Budget Name'),
                              ),
                            ),
                            /*
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: 250,
                                    child: TextFormField(
                                      keyboardType: TextInputType.number,
                                      onChanged: (newText) {
                                        setState(() {
                                          budgetAmount = int.parse(newText);
                                        });
                                      },
                                      decoration: InputDecoration(
                                          hintText: 'Amount',
                                          border: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(8)))),
                                    ),
                                  ),
                                  DropdownButton(
                                      onChanged: (String? newValue) {
                                        setModalState(() {
                                          currency = newValue!;
                                        });
                                      },
                                      value: currency,
                                      items: <String>[
                                        'Birr',
                                        'Dollar',
                                        'Durham',
                                        'Euro',
                                        'Pound',
                                        'Shilling'
                                      ]
                                          .map<DropdownMenuItem<String>>(
                                              (String value) =>
                                                  DropdownMenuItem<String>(
                                                      value: value,
                                                      child: Text(value)))
                                          .toList()),
                                ],
                              ),
                            ),*/
                            MoneyEditor(
                              initial:
                                  MonetaryAmount(currency: "ETB", amount: 0),
                              onSavedWhole: (v) => setState(() {
                                amountWholes = v;
                              }),
                              onSavedCents: (v) => setState(() {
                                amountCents = v;
                              }),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 4, 8, 0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Checkbox(
                                      value: isOneTime,
                                      onChanged: (bool? value) => setModalState(
                                          () => isOneTime = value!)),
                                  Text('One Time'),
                                  if (!isOneTime)
                                    SizedBox(
                                      width: 100,
                                    ),
                                  if (!isOneTime)
                                    DropdownButton(
                                        onChanged: (String? newValue) {
                                          recurringIntervals = newValue!;
                                          setModalState(() {});
                                        },
                                        value: recurringIntervals,
                                        items: <String>[
                                          'Every Day',
                                          'Every Week',
                                          'Every two Weeks',
                                          'Every Month'
                                        ]
                                            .map((String value) =>
                                                DropdownMenuItem(
                                                    value: value,
                                                    child: Text(value)))
                                            .toList())
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  CalendarPicker(
                                    dateController: startDateController,
                                    fieldName: 'Start Date',
                                    helpText: 'Start date of your new budget',
                                  ),
                                  if (isOneTime == true)
                                    Text(
                                      'To',
                                      textScaleFactor: 1.5,
                                    ),
                                  if (isOneTime == true)
                                    CalendarPicker(
                                      dateController: endDateController,
                                      fieldName: 'End Date',
                                      helpText: 'End date of your new budget',
                                    )
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ElevatedButton(
                                style: ButtonStyle(
                                    minimumSize:
                                        MaterialStateProperty.resolveWith(
                                            (states) => Size(150, 50))),
                                onPressed: () {
                                  print('Add Budget Clicked');
                                  print(
                                      'newBudgetName: $newBudgetName budgetAmount: $budgetAmount startDate: $_startDate endDate: $_endDate');

                                  /*
                                    final form = formKey.currentState;
                                    if (form != null && form.validate()) {
                                      print("passed the VAlIDATION");
                                      context.read<BudgetsBloc>().add(CreateBudget(
                                              item: Budget(
                                            id: 'hjdsf89y3rjhvo8309jde62m',
                                            createdAt: DateTime.now(),
                                            updatedAt: DateTime.now(),
                                            name: newBudgetName,
                                            startTime: startDate!,
                                            endTime: endDate!,
                                            allocatedAmount: MonetaryAmount(
                                                amount: int.parse(budgetAmount),
                                                currency: currency),
                                            frequency: isOneTime
                                                ? OneTime()
                                                : Recurring(
                                                    daytimeToSecondsConverter(
                                                        recurringIntervals)),
                                            categories: [],
                                          )));

                                      Navigator.pushReplacementNamed(
                                          context, BudgetListPage.routeName);
                                    }

                                     */

                                  if (isNewBudgetValid(
                                      context: context,
                                      newBudgetName: newBudgetName,
                                      budgetAmount: amountWholes,
                                      startDate: _startDate,
                                      endDate: _endDate)) {
                                    print("passed the VAlIDATION");
                                    amount = amountWholes.toString() +
                                        amountCents.toString();
                                    context
                                        .read<BudgetsBloc>()
                                        .add(CreateBudget(
                                            item: Budget(
                                          id: 'hjdsf89y3rjhvo8309jde62m',
                                          createdAt: DateTime.now(),
                                          updatedAt: DateTime.now(),
                                          name: newBudgetName,
                                          startTime: _startDate!,
                                          endTime: isOneTime
                                              ? _endDate!
                                              : budgetEndDateCalculator(
                                                  startDate: _startDate!,
                                                  interval: recurringIntervals),
                                          allocatedAmount: MonetaryAmount(
                                              amount: int.parse(amount),
                                              currency: currency),
                                          frequency: isOneTime
                                              ? OneTime()
                                              : Recurring(
                                                  daytimeToSecondsConverter(
                                                      recurringIntervals)),
                                          categories: {},
                                        )));
                                    Navigator.pushReplacementNamed(
                                        context, BudgetListPage.routeName);
                                  }

                                  startDateController.dispose();
                                  endDateController.dispose();
                                },
                                child: Text('Add Budget'),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                );
              });
        },
        child: Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  DateTime budgetEndDateCalculator(
      {required DateTime startDate, required String interval}) {
    switch (interval) {
      case 'Every day':
        return startDate.add(Duration(days: 1));
      case 'Every Week':
        return startDate.add(Duration(days: 7));
      case 'Every two Weeks':
        return startDate.add(Duration(days: 14));
      case 'Every Month':
        return startDate.add(Duration(days: 30));
      default:
        return startDate.add(Duration(days: 30));
    }
  }
}

class CalendarPicker extends StatelessWidget {
  final String fieldName;
  final String helpText;
  CalendarPicker({
    Key? key,
    required this.dateController,
    required this.fieldName,
    required this.helpText,
  }) : super(key: key);

  final TextEditingController dateController;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 60,
      child: TextFormField(
        controller: dateController,
        readOnly: true,
        autofocus: true,
        decoration: InputDecoration(
            hintText: fieldName,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffix: IconButton(
              autofocus: true,
              icon: Icon(Icons.calendar_today),
              onPressed: () async {
                if (fieldName == 'Start Date') {
                  DateTime? pickedDay = await showDatePicker(
                      context: context,
                      helpText: helpText,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(9999));
                  _startDate = pickedDay;
                  if (pickedDay != null)
                    dateController.text =
                        '${pickedDay.month.toString()}/${pickedDay.day.toString()}/${pickedDay.year.toString()}';
                } else if (fieldName == 'End Date') {
                  if (_startDate == null) {
                    var snackBar =
                        SnackBar(content: Text("Choose start day first"));
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    return;
                  }
                  DateTime? pickedDay = await showDatePicker(
                      context: context,
                      helpText: helpText,
                      initialDate: _startDate!,
                      firstDate: _startDate!,
                      lastDate: DateTime(9999));
                  _endDate = pickedDay;
                  if (pickedDay != null)
                    dateController.text =
                        '${pickedDay.month.toString()}/${pickedDay.day.toString()}/${pickedDay.year.toString()}';
                }
              },
            )),
      ),
    );
  }

  //DateTime pickedDate(DateTime
}

int daytimeToSecondsConverter(String chosenTime) {
  switch (chosenTime) {
    case 'Every day':
      return 86400;
    case 'Every week':
      return 604800;
    case 'Every two weeks':
      return 1209600;
    case 'Every month':
      return 2592000;
    default:
      return 604800;
  }
}

bool isNewBudgetValid(
    {required BuildContext context,
    required String newBudgetName,
    required int budgetAmount,
    DateTime? startDate,
    DateTime? endDate}) {
  SnackBar? snackBar;
  print('Validation Started');
  if (newBudgetName.isEmpty) {
    snackBar = SnackBar(
      content: Text("Budget Name wasn't given"),
      behavior: SnackBarBehavior.floating,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    print('No name given');
    return false;
  } else if (budgetAmount == null) {
    snackBar = SnackBar(content: Text("Budget Amount wasn't given"));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    print('No amount given');
    return false;
  } else if (startDate == null) {
    snackBar = SnackBar(content: Text("Start date wasn't given"));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    print('No Start Date given');
    return false;
  } else if (endDate == null) {
    snackBar = SnackBar(content: Text("End date wasn't given"));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    print('No End date given');
    return false;
  } else {
    return true;
  }
}
