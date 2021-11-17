export 'budget_list_view.dart';
export 'budget_selector.dart';
export 'category_list_view.dart';
export 'category_selector.dart';
export 'expense_list_view.dart';
export 'money_editor.dart';
export 'simple_date_range_editor.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/screens/Expense/expense_edit_page.dart';
import 'package:smuni/utilities.dart';

class DotSeparator extends StatelessWidget {
  const DotSeparator({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Icon(
          Icons.circle_rounded,
          size: 8,
        ),
      );
}

List<Widget> defaultActionButtons(BuildContext context) {
  final mainBudget = context
      .read<PreferencesBloc>()
      .preferencesLoadSuccessState()
      .preferences
      .mainBudget;
  var awaitingOp = false;
  return [
    if (mainBudget != null)
      Padding(
        padding: const EdgeInsets.only(bottom: 4.0, top: 8.0),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(
            context,
            ExpenseEditPage.routeName,
            arguments: ExpenseEditPageNewArgs(
              budgetId: mainBudget,
            ),
          ),
          label: Text('Expense'),
          icon: Icon(Icons.add),
        ),
      ),
    StatefulBuilder(
      builder: (context, setState) => !awaitingOp
          ? Padding(
              padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
              child: FloatingActionButton.extended(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  setState(() => awaitingOp = true);
                  context.read<SyncBloc>().add(TrySync(
                        onSuccess: () {
                          setState(() => awaitingOp = false);
                        },
                        onError: (err) {
                          setState(() => awaitingOp = false);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: err is ConnectionException
                                  ? Text('Connection Failed')
                                  : err is ConnectionException
                                      ? Text('Not Signed In')
                                      : Text('Unknown Error Occured'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ));
                },
                label: const Text("Sync"),
              ),
            )
          : const CircularProgressIndicator(),
    )
  ];
}
