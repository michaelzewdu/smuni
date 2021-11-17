import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/utilities.dart';

class IncomeListView extends StatefulWidget {
  final Map<String, Income> items;
  final bool dense;
  final FutureOr<void> Function(String?)? onSelected;
  final FutureOr<void> Function(String)? onDelete;
  final FutureOr<void> Function(String)? onEdit;

  const IncomeListView({
    Key? key,
    required this.items,
    this.dense = false,
    this.onDelete,
    this.onEdit,
    this.onSelected,
  }) : super(key: key);

  @override
  State<IncomeListView> createState() => _IncomeListViewState();
}

class _IncomeListViewState extends State<IncomeListView> {
  @override
  Widget build(BuildContext context) {
    final keys = widget.items.keys.toList();
    return ExpansionPanelList.radio(
      dividerColor: Colors.transparent,
      expandedHeaderPadding: const EdgeInsets.symmetric(vertical: 2),
      animationDuration: Duration(milliseconds: 400),
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          if (widget.onSelected != null) {
            widget.onSelected!
                .call(isExpanded ? widget.items[keys[index]]!.id : null);
          }
        });
      },
      children: keys
          .map((k) => widget.items[k]!)
          .map<ExpansionPanel>((item) => ExpansionPanelRadio(
                value: item.id,
                canTapOnHeader: true,
                headerBuilder: (BuildContext context, bool isExpanded) =>
                    ListTile(
                  title: Text(
                    item.name,
                    textScaleFactor: 1.25,
                  ),
                  dense: widget.dense,
                  trailing: Text(
                    "${item.amount.currency} ${item.amount.amount / 100}",
                  ),
                  subtitle: Text(
                    humanReadableTimeRelationName(
                        item.timestamp, DateTime.now()),
                  ),
                ),
                body: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      if (item.frequency is OneTime)
                        ListTile(
                          dense: true,
                          title: Text(humanReadableDateTime(item.timestamp)),
                        ),
                      if (item.frequency is Recurring)
                        Builder(builder: (context) {
                          final freq = item.frequency as Recurring;
                          final cycles = pastCycleDateRanges(
                            freq,
                            item.timestamp,
                            item.timestamp.add(
                                Duration(seconds: freq.recurringIntervalSecs)),
                            DateTime.now(),
                          );
                          return Column(
                            children: [
                              ListTile(
                                dense: true,
                                title: Text(
                                  'Next payout on: ${humanReadableDateTime(cycles[0].range.end)}',
                                ),
                              ),
                              ListTile(
                                dense: true,
                                title: Text(
                                  '${cycles.length} past payouts.',
                                ),
                              ),
                            ],
                          );
                        }),
                      if (widget.onEdit != null || widget.onDelete != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            if (widget.onEdit != null)
                              Center(
                                child: TextButton.icon(
                                    onPressed: () =>
                                        widget.onEdit?.call(item.id),
                                    label: Text("Edit"),
                                    icon: Icon(Icons.edit)),
                              ),
                            if (widget.onDelete != null)
                              TextButton.icon(
                                  onPressed: () =>
                                      widget.onDelete?.call(item.id),
                                  label: Text("Delete"),
                                  icon: Icon(Icons.delete))
                          ],
                        ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}
