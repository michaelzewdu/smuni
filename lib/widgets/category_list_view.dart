import 'package:flutter/material.dart';
import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/models/models.dart';

class CategoryListView extends StatelessWidget {
  final CategoriesLoadSuccess state;
  final void Function(String)? onSelect;
  final Set<String> disabledItems;
  const CategoryListView({
    Key? key,
    required this.state,
    this.onSelect,
    this.disabledItems = const {},
  }) : super(key: key);

  Widget _listTile(BuildContext context, Category item) {
    final isDisabled = disabledItems.contains(item.id);
    return ListTile(
      dense: isDisabled,
      title: Text(
        item.name,
        style: TextStyle(fontSize: 18),
      ),
      subtitle: Text(item.tags.map((e) => "#$e").toList().join(" ")),
      onTap: () => !isDisabled ? onSelect?.call(item.id) : null,
    );
  }

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
        ? _listTile(context, item)
        : Column(
            children: [
              _listTile(context, item),
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
            itemCount: topNodes.length,
            itemBuilder: (context, index) =>
                _catDisplay(context, topNodes[index].item),
          )
        : state.items.isEmpty
            ? const Center(child: Text("No categories."))
            : throw Exception("parents are missing");
  }
}
