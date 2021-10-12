import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/category_list_page.dart';
import 'package:smuni/blocs/edit_page.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/widgets/category_selector.dart';

class CategoryEditPage extends StatefulWidget {
  static const String routeName = "categoryEdit";

  const CategoryEditPage({Key? key}) : super(key: key);

  static Route route(String id) => MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (context) => BlocProvider(
          create: (context) =>
              EditPageBloc.fromRepo(context.read<CategoryRepository>(), id),
          child: CategoryEditPage(),
        ),
      );

  static Route routeNew() => MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) {
        final now = DateTime.now();
        final item = Category(
          id: "id-${now.microsecondsSinceEpoch}",
          createdAt: now,
          updatedAt: now,
          name: "",
          tags: [],
        );
        return BlocProvider(
          create: (context) =>
              EditPageBloc.modified(context.read<CategoryRepository>(), item),
          child: CategoryEditPage(),
        );
      });

  @override
  State<StatefulWidget> createState() => _CategoryEditPageState();
}

class _CategoryEditPageState extends State<CategoryEditPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = "";
  bool _isSubcategory = false;
  String? _parentId;

  Widget _showForm(BuildContext context, UnmodifiedEditState state) => Form(
        key: _formKey,
        child: Scaffold(
          appBar: AppBar(
            title: Text("Editing category: ${state.unmodified.name}"),
            actions: [
              ElevatedButton(
                onPressed: () {
                  final form = _formKey.currentState;
                  if (form != null && form.validate()) {
                    form.save();
                    context.read<EditPageBloc<String, Category>>()
                      ..add(
                        ModifyItem(
                          Category.from(
                            state.unmodified,
                            name: _name,
                            parentId: _parentId,
                          ),
                        ),
                      )
                      ..add(SaveChanges());
                    Navigator.pop(context, true);
                  }
                },
                child: const Text("Save"),
              ),
              ElevatedButton(
                onPressed: () {
                  context
                      .read<EditPageBloc<String, Category>>()
                      .add(DiscardChanges());
                  Navigator.pop(context, false);
                },
                child: const Text("Cancel"),
              ),
            ],
          ),
          body: Column(
            children: <Widget>[
              TextFormField(
                initialValue: state.unmodified.name,
                onSaved: (value) {
                  setState(() {
                    _name = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Name can't be empty";
                  }
                },
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: "Name",
                  helperText: "Name",
                ),
              ),
              Text("id: ${state.unmodified.id}"),
              Text("createdAt: ${state.unmodified.createdAt}"),
              Text("updatedAt: ${state.unmodified.updatedAt}"),
              // Text("category: ${state.unmodified.categoryId}"),
              CheckboxListTile(
                value: _isSubcategory,
                title: const Text("Is Subcategory"),
                onChanged: (value) => setState(() {
                  _isSubcategory = value!;
                }),
              ),
              if (_isSubcategory)
                BlocProvider(
                    create: (context) => CategoryListPageBloc(
                        context.read<CategoryRepository>()),
                    child: Expanded(
                      child: CategoryFormSelector(
                        caption: Text("Parent category"),
                        initialValue: state.unmodified.parentId == null
                            ? null
                            : state.unmodified.parentId!,
                        onChanged: (value) {
                          setState(() {
                            _parentId = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return "Parent category not selected";
                          }
                        },
                      ),
                    )),
              Column(
                children: [],
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => BlocConsumer<
          EditPageBloc<String, Category>, EditPageBlocState<String, Category>>(
        listener: (context, state) {
          if (state is UnmodifiedEditState<String, Category>) {
            final value = state is ModifiedEditState<String, Category>
                ? state.modified.parentId != null
                : state.unmodified.parentId != null;
            if (value != _isSubcategory) {
              setState(() {
                _isSubcategory = value;
              });
            }
          }
        },
        builder: (context, state) {
          if (state is UnmodifiedEditState<String, Category>) {
            return _showForm(context, state);
          } else if (state is LoadingItem) {
            return Scaffold(
              appBar: AppBar(
                title: const Text("Loading category..."),
              ),
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (state is ItemNotFound<String, Category>) {
            return Scaffold(
              appBar: AppBar(
                title: const Text("Item not found"),
              ),
              body: Center(
                child: Text(
                  "Error: unable to find item at id: ${state.id}.",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          throw Exception("Unhandled state");
        },
      );
}
