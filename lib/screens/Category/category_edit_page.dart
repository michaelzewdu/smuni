import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smuni/blocs/category_edit_page.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/widgets/budget_selector.dart';
import 'package:smuni/widgets/category_selector.dart';
import 'package:smuni/widgets/money_editor.dart';

class CategoryEditPage extends StatefulWidget {
  static const String routeName = "categoryEdit";

  const CategoryEditPage({Key? key}) : super(key: key);

  static Route route(String id) => MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (context) => BlocProvider(
          create: (context) =>
              CategoryEditPageBloc(context.read<CategoryRepository>(), id),
          child: CategoryEditPage(),
        ),
      );

  static Route routeNew() => MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) {
        final now = DateTime.now();
        final item = Category(
          id: "new-id",
          createdAt: now,
          updatedAt: now,
          name: "",
          tags: [],
          budgetId: "",
          allocatedAmount: MonetaryAmount(currency: "ETB", amount: 0),
        );
        return BlocProvider(
          create: (context) => CategoryEditPageBloc.modified(
              context.read<CategoryRepository>(), item),
          child: CategoryEditPage(),
        );
      });

  @override
  State<StatefulWidget> createState() => _CategoryEditPageState();
}

class _CategoryEditPageState extends State<CategoryEditPage> {
  final _formKey = GlobalKey<FormState>();
  int _amountWholes = 0;
  int _amountCents = 0;
  String _name = "";
  bool _isSubcategory = false;
  String _budgetId = "";
  String? _parentId;

  Widget _showForm(BuildContext context, UnmodifiedEditState state) => Form(
        key: _formKey,
        child: Scaffold(
          appBar: AppBar(
            title: Text("Editing category: ${state.unmodified.name}"),
            actions: [
              ElevatedButton(
                onPressed: () {
                  final form = this._formKey.currentState;
                  if (form != null && form.validate()) {
                    form.save();
                    context.read<CategoryEditPageBloc>()
                      ..add(
                        ModifyItem(
                          Category.from(state.unmodified,
                              name: _name,
                              allocatedAmount: MonetaryAmount(
                                  currency: "ETB",
                                  amount: (_amountWholes * 100) + _amountCents),
                              parentId: _parentId,
                              budgetId: _budgetId),
                        ),
                      )
                      ..add(SaveChanges());
                    /* Navigator.popAndPushNamed(
                      context,
                      CategoryDetailsPage.routeName,
                      arguments: bloc.state.unmodified.id,
                    ); */
                    Navigator.pop(context, true);
                  }
                },
                child: const Text("Save"),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<CategoryEditPageBloc>().add(DiscardChanges());
                  Navigator.pop(context, false);
                },
                child: const Text("Cancel"),
              ),
            ],
          ),
          body: BlocBuilder<CategoryEditPageBloc, CategoryEditPageBlocState>(
            builder: (context, state) => Column(
              children: <Widget>[
                if (state is UnmodifiedEditState)
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
                if (state is UnmodifiedEditState)
                  MoneyEditor(
                    initial: state.unmodified.allocatedAmount,
                    onSavedWhole: (v) => setState(() {
                      _amountWholes = v;
                    }),
                    onSavedCents: (v) => setState(() {
                      _amountCents = v;
                    }),
                  ),
                if (state is UnmodifiedEditState)
                  Text("id: ${state.unmodified.id}"),
                if (state is UnmodifiedEditState)
                  Text("createdAt: ${state.unmodified.createdAt}"),
                if (state is UnmodifiedEditState)
                  Text("updatedAt: ${state.unmodified.updatedAt}"),
                if (state is UnmodifiedEditState)
                  Text("budget: ${state.unmodified.budgetId}"),
                // Text("category: ${state.unmodified.categoryId}"),
                Column(
                  children: [
                    CheckboxListTile(
                      value: _isSubcategory,
                      onChanged: (value) => setState(() {
                        _isSubcategory = value!;
                      }),
                      title: const Text("Is Subcategory"),
                    ),
                    if (state is UnmodifiedEditState)
                      _isSubcategory
                          ? CategorySelector(
                              caption: "Parent category",
                              initialValue: state.unmodified.parentId == null
                                  ? null
                                  : CategorySelectorState(
                                      state.unmodified.parentId!,
                                      state.unmodified.budgetId),
                              onSaved: (value) {
                                setState(() {
                                  _parentId = value!.id;
                                  _budgetId = value.budgetId;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return "Parent category not selected";
                                }
                              },
                            )
                          : BudgetSelector(
                              initialValue: state.unmodified.budgetId.isEmpty
                                  ? null
                                  : state.unmodified.budgetId,
                              onSaved: (value) {
                                setState(() {
                                  _budgetId = value!;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return "No budget selected";
                                }
                              },
                            )
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<CategoryEditPageBloc, CategoryEditPageBlocState>(
        listener: (context, state) {
          if (state is UnmodifiedEditState) {
            final value = state is ModifiedEditState
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
          if (state is UnmodifiedEditState) {
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
          } else if (state is ItemNotFound) {
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
