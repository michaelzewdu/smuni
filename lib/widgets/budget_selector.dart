import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smuni/blocs/budget_list_page.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/utilities.dart';

import 'budget_list_view.dart';

class BudgetFormSelector extends FormField<String> {
  BudgetFormSelector({
    Key? key,
    Widget? caption,
    String? initialValue,
    FormFieldSetter<String>? onSaved,
    void Function(String?)? onChanged,
    FormFieldValidator<String>? validator,
    bool isSelecting = false,
    // AutovalidateMode? autovalidateMode,
    // bool? enabled,
    String? restorationId,
  }) : super(
          key: key,
          initialValue: initialValue,
          validator: validator,
          onSaved: onSaved,
          restorationId: restorationId,
          builder: (state) => BudgetSelector(
            isSelecting: isSelecting,
            caption: state.errorText != null
                ? Text(state.errorText!, style: TextStyle(color: Colors.red))
                : caption,
            initialValue: state.value,
            onChanged: (value) {
              state.didChange(value);
              onChanged?.call(value);
            },
          ),
        );
}

class BudgetSelector extends StatefulWidget {
  final Widget? caption;
  final String? initialValue;
  final void Function(String)? onChanged;
  final bool isSelecting;

  const BudgetSelector({
    Key? key,
    this.caption,
    this.onChanged,
    this.initialValue,
    this.isSelecting = false,
  }) : super(key: key);

  @override
  _BudgetSelectorState createState() =>
      _BudgetSelectorState(isSelecting, initialValue);
}

class _BudgetSelectorState extends State<BudgetSelector> {
  bool _isSelecting;
  String? _selectedBudgetId;

  _BudgetSelectorState(this._isSelecting, this._selectedBudgetId);

  void _selectBudget(String id) {
    setState(() {
      _selectedBudgetId = id;
      _isSelecting = false;
    });
    widget.onChanged?.call(id);
  }

  Widget _viewing(
    // FormFieldState<String> state,
    BudgetsLoadSuccess itemsState,
  ) {
    if (_selectedBudgetId != null) {
      final item = itemsState.items[_selectedBudgetId];
      if (item != null) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SizedBox(
              height: 8,
            ),
            Text(
              " ${item.name}",
              textScaleFactor: 2,
            ),
            SizedBox(height: 50),
            // Text("id: ${item.id}"),
            //Text("createdAt: ${item.createdAt}"),
            //Text("updatedAt: ${item.updatedAt}"),
            Text(
              "AllocatedAmount: ETB ${item.allocatedAmount.amount / 100}",
              textScaleFactor: 1.2,
            ),
            Text(
              "Started On: ${item.startTime.day} ${monthNames[item.startTime.month]} ${item.startTime.year}",
              textScaleFactor: 1.2,
            ),
            Text(
              "End Date: ${item.endTime.day} ${monthNames[item.endTime.month]} ${item.endTime.year}",
              textScaleFactor: 1.2,
            ),
            item.frequency.kind == FrequencyKind.recurring
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Frequency: Recurring',
                        textScaleFactor: 1.2,
                      ),
                      Text(
                        'Recurring Intervals: ${(((item.frequency as Recurring).recurringIntervalSecs) ~/ 86400)} days',
                        textScaleFactor: 1.2,
                      )
                    ],
                  )
                : Text(
                    'Frequency: OneTime',
                    textScaleFactor: 1.2,
                  ),
          ],
        );
      } else {
        return Center(child: const Text("Error: selected item not found."));
      }
    } else {
      return const Center(child: Text("No budget selected."));
    }
  }

  Widget _selecting(
    BudgetsLoadSuccess itemsState,
  ) =>
      Expanded(
          child: BudgetListView(
        state: itemsState,
        onSelect: (id) => _selectBudget(id),
      ));

  @override
  Widget build(BuildContext context) => Column(
        children: [
          // the top bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(children: [
              Expanded(
                child: widget.caption ??
                    const Text(
                      "Available Budgets",
                      textScaleFactor: 1.5,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
              ),
              if (!_isSelecting)
                TextButton(
                  child: const Text("Go Back"),
                  onPressed: () {
                    setState(() {
                      _isSelecting = !_isSelecting;
                    });
                  },
                )
            ]),
          ),
          BlocBuilder<BudgetListPageBloc, BudgetListPageBlocState>(
              builder: (context, itemsState) {
            if (itemsState is BudgetsLoadSuccess) {
              if (_isSelecting) {
                return _selecting(itemsState);
              } else {
                return _viewing(itemsState);
              }
            } else if (itemsState is BudgetsLoading) {
              return const Center(
                child: Text("Loading budgets..."),
              );
            }
            throw Exception("Unhandled state");
          })
        ],
      );
}
