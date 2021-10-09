import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smuni/blocs/budget_list_page.dart';

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
                : caption != null
                    ? caption
                    : null,
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
          children: [
            Text("Name: ${item.name}"),
            Text("id: ${item.id}"),
            Text("createdAt: ${item.createdAt}"),
            Text("updatedAt: ${item.updatedAt}"),
            Text(
              "allocatedAmount: ETB ${item.allocatedAmount.amount / 100}",
            ),
            Text("startTime: ${item.startTime}"),
            Text("endTime: ${item.endTime}"),
            Text("frequency: ${item.frequency.toJSON()}"),
          ],
        );
      } else {
        return Center(child: const Text("Error: selected item not found."));
      }
    } else {
      return const Center(child: const Text("No budget selected."));
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
          Row(children: [
            Expanded(
              child: widget.caption ??
                  const Text(
                    "Budget",
                  ),
            ),
            TextButton(
              child: _isSelecting ? const Text("Cancel") : const Text("Select"),
              onPressed: () {
                setState(() {
                  _isSelecting = !_isSelecting;
                });
              },
            )
          ]),
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
                child: const Text("Loading budgets..."),
              );
            }
            throw Exception("Unhandeled state");
          })
        ],
      );
}
