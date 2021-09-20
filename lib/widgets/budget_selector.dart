import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/budgets.dart';
import 'package:smuni/blocs/blocs.dart';

class BudgetSelector extends StatefulWidget {
  final String? caption;
  final String? initialValue;
  final FormFieldSetter<String>? onSaved;
  final FormFieldValidator<String>? validator;
  final String? restorationId;

  const BudgetSelector({
    Key? key,
    this.caption,
    this.initialValue,
    this.onSaved,
    this.validator,
    // AutovalidateMode? autovalidateMode,
    // bool? enabled,
    this.restorationId,
  }) : super(key: key);

  @override
  _BudgetSelectorState createState() => _BudgetSelectorState();
}

class _BudgetSelectorState extends State<BudgetSelector> {
  bool _isSelecting = false;

  Widget _viewing(
    FormFieldState<String> state,
    BudgetsLoadSuccess itemsState,
  ) {
    final value = state.value;
    if (value != null) {
      final item = itemsState.items[value];
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
    FormFieldState<String> state,
    BudgetsLoadSuccess itemsState,
  ) {
    // show the selection list
    final items = itemsState.items;
    final keys = items.keys;
    return items.isNotEmpty
        ? SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: ListView.builder(
              itemCount: keys.length,
              itemBuilder: (context, index) {
                final item = items[keys.elementAt(index)]!;
                return ListTile(
                  title: Text(item.name),
                  trailing: Text(
                    "${item.allocatedAmount.currency} ${item.allocatedAmount.amount / 100}",
                  ),
                  onTap: () {
                    state.didChange(
                      item.id,
                    );
                    setState(() {
                      _isSelecting = false;
                    });
                  },
                );
              },
            ),
          )
        : const Center(child: const Text("No budgets."));
  }

  @override
  Widget build(BuildContext context) => FormField<String>(
        initialValue: widget.initialValue,
        validator: widget.validator,
        onSaved: widget.onSaved,
        builder: (state) => Column(
          children: [
            // the top bar
            Row(children: [
              Expanded(
                  child: Text(
                state.errorText ?? widget.caption ?? "Budget",
                style: TextStyle(
                    color: state.errorText != null ? Colors.red : null),
              )),
              TextButton(
                child:
                    _isSelecting ? const Text("Cancel") : const Text("Select"),
                onPressed: () {
                  setState(() {
                    _isSelecting = !_isSelecting;
                  });
                },
              )
            ]),
            BlocBuilder<BudgetsBloc, BudgetsBlocState>(
                builder: (context, itemsState) {
              if (itemsState is BudgetsLoadSuccess) {
                if (_isSelecting) {
                  return _selecting(state, itemsState);
                } else {
                  return _viewing(state, itemsState);
                }
              } else if (itemsState is BudgetsLoading) {
                return const Center(
                  child: const Text("Loading budgets..."),
                );
              }
              throw Exception("Unhandeled state");
            })
          ],
        ),
      );
}
