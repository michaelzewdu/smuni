import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:smuni/blocs/budget_list_page.dart';

class BudgetListView extends StatelessWidget {
  final BudgetsLoadSuccess state;
  final void Function(String)? onSelect;
  const BudgetListView({Key? key, required this.state, this.onSelect})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // show the selection list
    final items = state.items;
    final keys = items.keys;
    return items.isNotEmpty
        ? ListView.builder(
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final item = items[keys.elementAt(index)]!;
              return ListTile(
                  title: Text(item.name),
                  trailing: Text(
                    "${item.allocatedAmount.currency} ${item.allocatedAmount.amount / 100}",
                  ),
                  onTap: () => onSelect?.call(item.id));
            },
          )
        : const Center(child: Text("No budgets."));
  }
}