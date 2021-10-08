import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/blocs.dart';

import 'category_list_view.dart';

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
        return Column(
          children: [
            Text("Name: ${item.name}"),
            Text("id: ${item.id}"),
            Text("createdAt: ${item.createdAt}"),
            Text("updatedAt: ${item.updatedAt}"),
            Text("parentId: ${item.parentId}"),
          ],
        );
      } else {
        return Center(child: const Text("Error: selected item not found."));
      }
    } else {
      return const Center(child: const Text("No category selected."));
    }
  }

  Widget _selecting(
    CategoriesLoadSuccess itemsState,
  ) =>
      Expanded(
        child: CategoryListView(
          state: itemsState,
          disabledItems: widget.disabledItems,
          onSelect: (id) => _selectCategory(id),
        ),
      );

  @override
  Widget build(BuildContext context) => Column(
        children: [
          // the top bar
          Row(children: [
            Expanded(
                child: widget.caption ??
                    const Text(
                      "Category",
                    )),
            TextButton(
              child: _isSelecting ? const Text("Cancel") : const Text("Select"),
              onPressed: () {
                setState(() {
                  _isSelecting = !_isSelecting;
                });
              },
            )
          ]),
          BlocBuilder<CategoryListPageBloc, CategoryListPageBlocState>(
              builder: (context, itemsState) {
            if (itemsState is CategoriesLoadSuccess) {
              if (_isSelecting) {
                return _selecting(itemsState);
              } else {
                return _viewing(itemsState);
              }
            } else if (itemsState is CategoriesLoading) {
              return const Center(
                child: const Text("Loading categories..."),
              );
            }
            throw Exception("Unhandeled state");
          })
        ],
      );
}
