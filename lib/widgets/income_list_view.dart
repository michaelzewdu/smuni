import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/utilities.dart';

class IncomeListView extends StatefulWidget {
  final Map<String, Income> items;
  final bool dense;
  final FutureOr<void> Function(String)? onDelete;
  final FutureOr<void> Function(String)? onEdit;

  const IncomeListView({
    Key? key,
    required this.items,
    this.dense = false,
    this.onDelete,
    this.onEdit,
  }) : super(key: key);

  @override
  State<IncomeListView> createState() => _IncomeListViewState();
}

class _IncomeListViewState extends State<IncomeListView> {
  String? _selectedItem;

  @override
  Widget build(BuildContext context) {
    final keys = widget.items.keys.toList();
    return ExpansionPanelList(
      dividerColor: Colors.transparent,
      expandedHeaderPadding: const EdgeInsets.symmetric(vertical: 2),
      animationDuration: Duration(milliseconds: 400),
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          final tappedId = widget.items[keys[index]]!.id;
          if (tappedId != _selectedItem) {
            _selectedItem = tappedId;
          } else {
            _selectedItem = null;
          }
        });
      },
      children: keys
          .map((k) => widget.items[k]!)
          .map<ExpansionPanel>((item) => ExpansionPanel(
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
                    '${monthNames[item.timestamp.month]} ${item.timestamp.day} ${item.timestamp.year}',
                  ),
                ),
                body: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Text(
                                'Income added on: ${monthNames[item.createdAt.month]} ${item.createdAt.day} ${item.createdAt.year}'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Text('TODO: show budget and category here'),
                          )
                        ],
                      ),
                      Column(
                        children: [
                          Center(
                            child: IconButton(
                                onPressed: () => widget.onEdit?.call(item.id),
                                icon: Icon(Icons.edit)),
                          ),
                          IconButton(
                              onPressed: () => widget.onDelete?.call(item.id),
                              icon: Icon(Icons.delete))
                        ],
                      )
                    ],
                  ),
                ),
                isExpanded: item.id == _selectedItem,
              ))
          .toList(),
    );
  }
}
