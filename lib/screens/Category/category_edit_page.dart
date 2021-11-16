import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni/widgets/widgets.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

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
        builder: (context) => BlocProvider(
          create: (context) => CategoryEditPageBloc(
            context.read<CategoryRepository>(),
            context.read<OfflineCategoryRepository>(),
            context.read<AuthBloc>(),
          ),
          child: CategoryEditPage(item: item, isCreating: false),
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
          create: (context) => CategoryEditPageBloc(
            context.read<CategoryRepository>(),
            context.read<OfflineCategoryRepository>(),
            context.read<AuthBloc>(),
          ),
          child: CategoryEditPage(item: item, isCreating: true),
        );
      });

  @override
  State<StatefulWidget> createState() => _CategoryEditPageState();
}

class _CategoryEditPageState extends State<CategoryEditPage> {
  final _formKey = GlobalKey<FormState>();

  late var _name = widget.item.name;
  late String? _parentId = widget.item.parentId;
  late var tags = widget.item.tags;

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
                : FittedBox(child: Text(widget.item.name)),
            actions: !_awaitingSave
                ? [
                    ElevatedButton(
                      child: const Text("Save"),
                      onPressed: () {
                        final form = _formKey.currentState;
                        if (form != null && form.validate()) {
                          form.save();

                          if (widget.isCreating) {
                            context.read<CategoryEditPageBloc>().add(
                                  CreateCategory(CreateCategoryInput(
                                    name: _name,
                                    parentId: _parentId,
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
                                          parentId: _parentId ?? "",
                                        ),
                                        old: widget.item,
                                      )),
                                );
                          }
                          setState(() => _awaitingSave = true);
                        }
                      },
                    ),
                    ElevatedButton(
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
                  /*
                  Text("createdAt: ${widget.item.createdAt}"),
                  Text("updatedAt: ${widget.item.updatedAt}"),

                   */
                  // Text("category: ${state.unmodified.categoryId}"),

                  BlocProvider(
                    create: (context) => CategoryListPageBloc(
                      context.read<CategoryRepository>(),
                      context.read<OfflineCategoryRepository>(),
                    ),
                    child: Expanded(
                      child: CategoryFormSelector(
                        isSelecting: widget.isCreating,
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
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
