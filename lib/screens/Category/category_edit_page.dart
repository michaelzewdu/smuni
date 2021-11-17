import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni/widgets/widgets.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

class CategoryEditNewArgs {
  final String? parent;

  const CategoryEditNewArgs({this.parent});
}

class CategoryEditPage extends StatefulWidget {
  static const String routeName = "categoryEdit";

  final Category item;
  final bool isCreating;

  const CategoryEditPage({
    Key? key,
    required this.item,
    required this.isCreating,
  }) : super(key: key);

  static Route route(Category item) => MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => CategoryEditPageBloc(
                context.read<CategoryRepository>(),
                context.read<OfflineCategoryRepository>(),
                context.read<AuthBloc>(),
              ),
            ),
            BlocProvider(
              create: (context) => CategoryListPageBloc(
                context.read<CategoryRepository>(),
                context.read<OfflineCategoryRepository>(),
              ),
            ),
          ],
          child: CategoryEditPage(item: item, isCreating: false),
        ),
      );

  static Route routeNew(CategoryEditNewArgs args) => MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) {
        final now = DateTime.now();
        final item = Category(
          id: "id-${now.microsecondsSinceEpoch}",
          createdAt: now,
          updatedAt: now,
          name: "",
          tags: [],
          parentId: args.parent,
        );
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => CategoryEditPageBloc(
                context.read<CategoryRepository>(),
                context.read<OfflineCategoryRepository>(),
                context.read<AuthBloc>(),
              ),
            ),
            BlocProvider(
              create: (context) => CategoryListPageBloc(
                context.read<CategoryRepository>(),
                context.read<OfflineCategoryRepository>(),
              ),
            ),
          ],
          child: CategoryEditPage(item: item, isCreating: true),
        );
      });

  @override
  State<StatefulWidget> createState() => _CategoryEditPageState();
}

class _CategoryEditPageState extends State<CategoryEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _tagEditorKey = GlobalKey<FormFieldState<String>>();
  final _tagEditorController = TextEditingController();

  late var _name = widget.item.name;
  late String? _parentId = widget.item.parentId;
  late bool _isSubcategory = widget.isCreating || widget.item.parentId != null;
  late final _tags = <String>{...widget.item.tags};

  String? _nextNewTag;
  bool _awaitingSave = false;

  @override
  Widget build(BuildContext context) =>
      BlocListener<CategoryEditPageBloc, CategoryEditPageBlocState>(
        listener: (context, state) {
          if (state is CategoryEditSuccess) {
            if (_awaitingSave) setState(() => {_awaitingSave = false});
            Navigator.pop(context);
          } else if (state is CategoryEditFailed) {
            if (_awaitingSave) setState(() => {_awaitingSave = false});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: state.error is ConnectionException
                    ? Text('Connection Failed')
                    : state.error is UnseenVersionException
                        ? Text(
                            'Desync error: sync first',
                          )
                        : Text('Unknown Error Occured'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            throw Exception("Unhandled type");
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: _awaitingSave
                ? const Text("Loading...")
                : widget.item.name.isEmpty
                    ? Text("New category")
                    : FittedBox(child: Text(widget.item.name)),
            actions: !_awaitingSave
                ? [
                    TextButton(
                      child: const Text("Save"),
                      onPressed: () {
                        final form = _formKey.currentState;
                        if (form != null && form.validate()) {
                          form.save();

                          if (widget.isCreating) {
                            context.read<CategoryEditPageBloc>().add(
                                  CreateCategory(CreateCategoryInput(
                                    name: _name,
                                    parentId: _isSubcategory ? _parentId : null,
                                    tags: _tags.toList(),
                                  )),
                                );
                          } else {
                            context.read<CategoryEditPageBloc>().add(
                                  UpdateCategory(
                                      widget.item.id,
                                      UpdateCategoryInput.fromDiff(
                                        update: Category.from(
                                          widget.item,
                                          name: _name,
                                          parentId:
                                              _isSubcategory ? _parentId : "",
                                          tags: _tags.toList(),
                                        ),
                                        old: widget.item,
                                      )),
                                );
                          }
                          setState(() => _awaitingSave = true);
                        }
                      },
                    ),
                    TextButton(
                      child: const Text("Cancel"),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ]
                : null,
          ),
          body: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: <Widget>[
                  TextFormField(
                    initialValue: _name,
                    onSaved: (value) => setState(() => _name = value!),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Name can't be empty";
                      }
                    },
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8))),
                      hintText: "Name",
                      helperText: "Name",
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child:
                            StatefulBuilder(builder: (context, setWidgetState) {
                          return TextField(
                            key: _tagEditorKey,
                            controller: _tagEditorController,
                            onChanged: (value) =>
                                setWidgetState(() => _nextNewTag = value),
                            decoration: InputDecoration(
                              suffixIcon: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: _nextNewTag != null &&
                                        _nextNewTag!.isNotEmpty &&
                                        !_tags.contains(_nextNewTag)
                                    ? ElevatedButton(
                                        onPressed: () {
                                          setState(
                                            () => _tags.add(_nextNewTag!
                                                .trim()
                                                .split(" ")
                                                .join()),
                                          );
                                          _tagEditorController.clear();
                                        },
                                        child: const Text("New tag"),
                                      )
                                    : null,
                              ),
                              border: const OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8)),
                              ),
                              hintText: "New Tag",
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                  Container(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("Tags"),
                        ),
                        ..._tags.map(
                          (e) => Chip(
                            label: Text("#$e"),
                            onDeleted: () => setState(() => _tags.remove(e)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CheckboxListTile(
                    value: _isSubcategory,
                    title: const Text("Is a Subcategory"),
                    onChanged: (value) =>
                        setState(() => _isSubcategory = value!),
                  ),
                  if (_isSubcategory)
                    Expanded(
                      child: CategoryFormSelector(
                        isSelecting: _parentId == null,
                        caption: Text("Parent category"),
                        disabledItems:
                            !widget.isCreating ? {widget.item.id} : null,
                        initialValue: _parentId == null ? null : _parentId!,
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
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}
