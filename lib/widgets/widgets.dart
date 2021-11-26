import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/screens/Expense/expense_edit_page.dart';
import 'package:smuni/utilities.dart';

import 'budget_selector.dart';
import 'category_selector.dart';

export 'budget_list_view.dart';
export 'budget_selector.dart';
export 'category_list_view.dart';
export 'category_selector.dart';
export 'expense_list_view.dart';
export 'money_editor.dart';
export 'simple_date_range_editor.dart';

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
          heroTag: null,
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
                heroTag: null,
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

void showMainBudgetSelectorModal(
  BuildContext context,
  void Function(
    String newMainBudget, {
    OperationSuccessNotifier? onSuccess,
    OperationExceptionNotifier? onError,
  })
      changeMainBudget, {
  String? initialSelection,
}) {
  final selectorKey = GlobalKey<FormFieldState<String>>();
  var budgetId = initialSelection ?? "";
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
                      caption: const Text(
                        "Select Main Budget",
                        textScaleFactor: 1.5,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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
                                Navigator.pop(context);
                              },
                              onError: (err) {
                                setState(() => awaitingOp = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: err is ConnectionException
                                        ? Text('Connection Failed')
                                        : err is UnseenVersionException
                                            ? Text('Desync error: sync first')
                                            : Text('Unknown Error Occurred'),
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

void showMiscCategorySelectorModal(
  BuildContext context,
  void Function(
    String newMiscCategoryBudget, {
    OperationSuccessNotifier? onSuccess,
    OperationExceptionNotifier? onError,
  })
      changeMiscCategory, {
  String? initalSelection,
}) {
  final selectorKey = GlobalKey<FormFieldState<String>>();
  var categoryId = initalSelection ?? "";
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
                  create: (context) => CategoryListPageBloc(
                    context.read<CategoryRepository>(),
                    context.read<OfflineCategoryRepository>(),
                  ),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: CategoryFormSelector(
                      key: selectorKey,
                      isSelecting: true,
                      caption: const Text(
                        "Select Misc Category",
                        textScaleFactor: 1.5,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onSaved: (value) => setState(() => categoryId = value!),
                      validator: (value) {
                        if (value == null) {
                          return "No category selected";
                        }
                      },
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: !awaitingOp && categoryId.isNotEmpty
                      ? () {
                          final selector = selectorKey.currentState;
                          if (selector != null && selector.validate()) {
                            selector.save();
                            changeMiscCategory(
                              categoryId,
                              onSuccess: () {
                                setState(() => awaitingOp = false);
                                Navigator.pop(context);
                              },
                              onError: (err) {
                                setState(() => awaitingOp = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: err is ConnectionException
                                        ? Text('Connection Failed')
                                        : err is UnseenVersionException
                                            ? Text('Desync error: sync first')
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
