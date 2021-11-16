import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/models/models.dart';

class CategoryListView extends StatelessWidget {
  final CategoriesLoadSuccess state;
  final void Function(String)? onSelect;
  final Set<String> disabledItems;
  final bool markArchived;
  const CategoryListView({
    Key? key,
    required this.state,
    this.onSelect,
    this.disabledItems = const {},
    this.markArchived = true,
  }) : super(key: key);

  static Widget listTile(
    BuildContext context,
    Category item, {
    bool showStatus = true,
    FutureOr<void> Function()? onTap,
    // bool isDisabled = false,
  }) =>
      ListTile(
        dense: onTap == null,
        trailing: showStatus
            ? item.isArchived
                ? const Text("In Trash")
                : const Text("Active")
            : null,
        title: Text(item.name),
        subtitle: Text(item.tags.map((e) => "#$e").toList().join(" ")),
        onTap: onTap,
      );

  Widget _catDisplay(
    BuildContext context,
    String id,
  ) {
    final item = state.items[id];
    final itemNode = state.ancestryGraph[id];
    if (item == null) return Text("Error: Category under id $id not found");
    if (itemNode == null) {
      return Text("Error: Category under id $id not found in ancestryGraph");
    }

    return itemNode.children.isEmpty
        ? listTile(
            context,
            item,
            showStatus: item.isArchived == markArchived,
            onTap: !disabledItems.contains(item.id) ||
                    item.isArchived != markArchived
                ? () => onSelect?.call(item.id)
                : null,
          )
        : Column(
            children: [
              listTile(context, item),
              Padding(
                padding: EdgeInsets.only(
                    left: MediaQuery.of(context).size.width * 0.05),
                child: Column(
                  children: [
                    ...itemNode.children.map((e) => _catDisplay(context, e)),
                  ],
                ),
              )
            ],
          );
  }

  @override
  Widget build(BuildContext context) {
    // show the selection list
    final topNodes =
        state.ancestryGraph.values.where((e) => e.parent == null).toList();

    return topNodes.isNotEmpty
        ? ListView.builder(
            shrinkWrap: true,
            itemCount: topNodes.length,
            itemBuilder: (context, index) =>
                _catDisplay(context, topNodes[index].item),
          )
        : Expanded(child: Center(child: Text("No categories.")));
  }
}
