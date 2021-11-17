import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni/widgets/widgets.dart';

class CategoryFormSelector extends FormField<String> {
  CategoryFormSelector({
    Key? key,
    Widget? caption,
    String? initialValue,
    FormFieldSetter<String>? onSaved,
    void Function(String?)? onChanged,
    FormFieldValidator<String>? validator,
    bool isSelecting = false,
    Set<String>? disabledItems,
    // AutovalidateMode? autovalidateMode,
    // bool? enabled,
    String? restorationId,
  }) : super(
          key: key,
          initialValue: initialValue,
          validator: validator,
          onSaved: onSaved,
          restorationId: restorationId,
          builder: (state) => CategorySelector(
            isSelecting: isSelecting,
            disabledItems: disabledItems ?? const {},
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

class CategorySelector extends StatefulWidget {
  final Widget? caption;
  final String? initialValue;
  final void Function(String)? onChanged;
  final bool isSelecting;
  final Set<String> disabledItems;

  const CategorySelector({
    Key? key,
    this.caption,
    this.initialValue,
    this.onChanged,
    this.isSelecting = false,
    this.disabledItems = const {},
  }) : super(key: key);

  @override
  _CategorySelectorState createState() => _CategorySelectorState(
        isSelecting,
        initialValue,
      );
}

class _CategorySelectorState extends State<CategorySelector> {
  bool _isSelecting;
  String? _selectedCategoryId;

  _CategorySelectorState(this._isSelecting, this._selectedCategoryId);

  void _selectCategory(String id) {
    setState(() {
      _selectedCategoryId = id;
      _isSelecting = false;
    });
    widget.onChanged?.call(id);
  }

  Widget _viewing(
    CategoriesLoadSuccess itemsState,
  ) {
    if (_selectedCategoryId != null) {
      final item = itemsState.items[_selectedCategoryId];
      if (item != null) {
        final parent =
            item.parentId != null ? itemsState.items[item.parentId] : null;
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Align(
                child: Text(item.name, textScaleFactor: 1.7),
                alignment: Alignment.center,
              ),
              if (item.tags.isNotEmpty)
                Text(item.tags.map((e) => "#$e").toList().join(" ")),
              if (parent != null) Text("Parent: ${parent.name}"),
            ],
          ),
        );
      } else {
        return Center(child: const Text("Error: selected item not found."));
      }
    } else {
      return const Center(child: Text("No category selected."));
    }
  }

  Widget _selecting(
    CategoriesLoadSuccess itemsState,
  ) {
    // ignore: prefer_collection_literals
    Set<String> rootNodes = LinkedHashSet();

    // FIXME: move this calculation
    final ancestryTree = CategoryRepositoryExt.calcAncestryTree(
      itemsState.items.keys.toSet().difference(widget.disabledItems),
      itemsState.items,
    );
    for (final node in ancestryTree.values.where((e) => e.parent == null)) {
      rootNodes.add(node.item);
    }

    return rootNodes.isNotEmpty
        ? ListView.builder(
            shrinkWrap: true,
            itemBuilder: (BuildContext context, int index) {
              final id = rootNodes.elementAt(index);
              return _catTree(
                context,
                itemsState.items,
                ancestryTree,
                id,
              );
            },
            itemCount: rootNodes.length,
          )
        : itemsState.items.isEmpty
            ? Center(child: const Text("No categories."))
            : throw Exception("error: parents are missing");
  }

  Widget _catTree(
    BuildContext context,
    Map<String, Category> items,
    Map<String, TreeNode<String>> nodes,
    String id,
  ) {
    final item = items[id];
    final itemNode = nodes[id];
    if (item == null) return Text("Error: Category under id $id not found");
    if (itemNode == null) {
      return Text("Error: Category under id $id not found in ancestryGraph");
    }

    return Column(
      children: [
        !widget.disabledItems.contains(id)
            ? ListTile(
                selected: _selectedCategoryId == id,
                title: Text(item.name),
                subtitle: item.tags.isNotEmpty || item.isArchived
                    ? Row(children: [
                        if (item.isArchived)
                          Text("In Trash", style: TextStyle(color: Colors.red)),
                        if (item.isArchived && item.tags.isNotEmpty)
                          const DotSeparator(),
                        if (item.tags.isNotEmpty)
                          Text(item.tags.map((e) => "#$e").toList().join(" ")),
                      ])
                    : null,
                onTap: () => _selectCategory(id),
              )
            : ListTile(
                dense: true,
                title: Text(item.name),
              ),
        if (itemNode.children.isNotEmpty)
          Padding(
            padding:
                EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.05),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ...itemNode.children.map(
                  (e) => _catTree(
                    context,
                    items,
                    nodes,
                    e,
                  ),
                ),
              ],
            ),
          )
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          // the top bar
          ListTile(
            dense: true,
            title: widget.caption ??
                const Text(
                  "Category",
                ),
            trailing: TextButton(
              child: _isSelecting
                  ? const Text("Cancel")
                  : _selectedCategoryId != null
                      ? const Text("Change")
                      : const Text("Select"),
              onPressed: () {
                setState(() {
                  _isSelecting = !_isSelecting;
                });
              },
            ),
          ),
          BlocBuilder<CategoryListPageBloc, CategoryListPageBlocState>(
              builder: (context, itemsState) {
            if (itemsState is CategoriesLoadSuccess) {
              if (_isSelecting) {
                return _selecting(itemsState);
              } else {
                return _viewing(itemsState);
              }
            } else if (itemsState is CategoriesLoading) {
              return const Center(child: Text("Loading categories..."));
            }
            throw Exception("Unhandeled state");
          })
        ],
      );
}
