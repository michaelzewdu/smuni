import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/models/models.dart';

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
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final item = items[keys.elementAt(index)]!;
              return listTile(context, item,
                  onTap: () => onSelect?.call(item.id));
            },
          )
        : const Center(child: Text("No budgets."));
  }

  static Widget listTile(
    BuildContext context,
    Budget item, {
    FutureOr<void> Function()? onTap,
  }) =>
      ListTile(
        dense: onTap == null,
        title: Text(
          item.name,
          textScaleFactor: 1.3,
        ),
        trailing: Text(
          "${item.allocatedAmount.currency} ${item.allocatedAmount.amount / 100}",
          textScaleFactor: 1.3,
        ),
        onTap: onTap,
      );
}
