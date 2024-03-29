import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni/widgets/widgets.dart';

import 'category_edit_page.dart';

class CategoryDetailsPage extends StatelessWidget {
  static const String routeName = "categoryDetails";

  static Route route(String id) => MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => CategoryDetailsPageBloc(
                  context.read<CategoryRepository>(),
                  context.read<OfflineCategoryRepository>(),
                  context.read<AuthBloc>(),
                  context.read<BudgetRepository>(),
                  context.read<OfflineBudgetRepository>(),
                  context.read<ExpenseRepository>(),
                  context.read<OfflineExpenseRepository>(),
                  context.read<SyncBloc>(),
                  context.read<PreferencesBloc>(),
                  id),
            ),
            BlocProvider(
              create: (context) => CategoryListPageBloc(
                context.read<CategoryRepository>(),
                context.read<OfflineCategoryRepository>(),
                LoadCategoriesFilter(
                  includeActive: true,
                  includeArchvied: true,
                ),
              ),
            ),
          ],
          child: CategoryDetailsPage(),
        ),
      );

  const CategoryDetailsPage({Key? key}) : super(key: key);

  static Widget _dialogActionButton(
    BuildContext context,
    CategoryLoadSuccess state, {
    bool disabled = false,
    required String butonTitle,
    required String dialogTitle,
    required String dialogContent,
    required String cancelButtonTitle,
    required String confirmButtonTitle,
    required CategoryDetailsPageEvent Function({
      OperationSuccessNotifier? onSuccess,
      OperationExceptionNotifier? onError,
    })
        eventGenerator,
  }) =>
      TextButton(
        child: Text(butonTitle),
        onPressed: () async {
          final confirm = await showDialog<bool?>(
            context: context,
            builder: (_) {
              var awaitingOp = false;
              return StatefulBuilder(
                builder: (dialogContext, setState) => AlertDialog(
                  title: Text(dialogTitle),
                  content: Text(dialogContent),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: Text(cancelButtonTitle),
                    ),
                    TextButton(
                      onPressed: !disabled && !awaitingOp
                          ? () {
                              context
                                  .read<CategoryDetailsPageBloc>()
                                  .add(eventGenerator(
                                    onSuccess: () {
                                      setState(() => awaitingOp = false);
                                      Navigator.pop(dialogContext, true);
                                    },
                                    onError: (err) {
                                      setState(() => awaitingOp = false);
                                      if (err is SyncException) {
                                        Navigator.pop(dialogContext, false);
                                        Navigator.popUntil(
                                          context,
                                          (route) => route.isFirst,
                                        );
                                      } else {
                                        ScaffoldMessenger.of(dialogContext)
                                            .showSnackBar(
                                          SnackBar(
                                            content: err is ConnectionException
                                                ? Text('Connection Failed')
                                                : err
                                                        is MiscCategoryArchivalForbidden
                                                    ? Text(
                                                        'Is default misc category.')
                                                    : err
                                                            is UnseenVersionException
                                                        ? Text(
                                                            'Desync error: sync first',
                                                          )
                                                        : Text(
                                                            'Unknown Error Occured'),
                                            behavior: SnackBarBehavior.floating,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                  ));
                              setState(() => awaitingOp = true);
                            }
                          : null,
                      child: !awaitingOp
                          ? Text(confirmButtonTitle)
                          : const CircularProgressIndicator(),
                    ),
                  ],
                ),
              );
            },
          );
          if (confirm != null && confirm) {
            Navigator.pop(context);
          }
        },
      );

  Widget _showDetails(
    BuildContext context,
    CategoryLoadSuccess state,
  ) =>
      Scaffold(
        appBar: AppBar(
          title: Text(state.item.name),
          actions: state.item.isArchived
              ? [
                  _dialogActionButton(
                    context,
                    state,
                    butonTitle: "Restore",
                    dialogTitle: "Confirm",
                    dialogContent:
                        "Are you sure you want to restore category ${state.item.name}?",
                    cancelButtonTitle: "Cancel",
                    confirmButtonTitle: "Restore",
                    eventGenerator: ({onError, onSuccess}) => UnarchiveCategory(
                      onSuccess: onSuccess,
                      onError: onError,
                    ),
                  ),
                  Builder(builder: (context) {
                    final isMiscCat = context
                            .read<PreferencesBloc>()
                            .preferencesLoadSuccessState()
                            .preferences
                            .miscCategory ==
                        state.item.id;

                    return _dialogActionButton(context, state,
                        butonTitle: "Delete",
                        dialogTitle: "Confirm deletion",
                        dialogContent: isMiscCat
                            ? "Category ${state.item.name} is selected as the default miscallenous category. "
                                "Please choose another one from the setting screen before deleting it."
                            : "Are you sure you want to permanently delete entry ${state.item.name}?"
                                "\nWARNING: All attached expenses will be moved to the default misc category.",
                        cancelButtonTitle: "Cancel",
                        confirmButtonTitle: "Delete",
                        eventGenerator: ({onError, onSuccess}) =>
                            DeleteCategory(
                              onSuccess: onSuccess,
                              onError: onError,
                            ),
                        disabled: isMiscCat);
                  }),
                ]
              : [
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      CategoryEditPage.routeName,
                      arguments: state.item,
                    ),
                    child: const Text("Edit"),
                  ),
                  Builder(builder: (context) {
                    final isMiscCat = context
                            .read<PreferencesBloc>()
                            .preferencesLoadSuccessState()
                            .preferences
                            .miscCategory ==
                        state.item.id;

                    return _dialogActionButton(
                      context,
                      state,
                      butonTitle: "Delete",
                      dialogTitle: "Confirm deletion",
                      dialogContent: isMiscCat
                          ? "Category ${state.item.name} is selected as the default miscallenous category. "
                              "Please choose another one from the setting screen before deleting it."
                          : "Are you sure you want to move Category ${state.item.name} to the trash?"
                              "\nAssociated expense entries won't removed and you can always recover it afterwards.",
                      cancelButtonTitle: "Cancel",
                      confirmButtonTitle: "Delete",
                      eventGenerator: ({onError, onSuccess}) => ArchiveCategory(
                        onSuccess: onSuccess,
                        onError: onError,
                      ),
                      disabled: isMiscCat,
                    );
                  }),
                ],
        ),
        body: Column(
          children: <Widget>[
            ListTile(
              title: Text(
                state.item.name,
                textScaleFactor: 2,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (state.item.tags.isNotEmpty)
              ListTile(
                leading: Text("Tags:"),
                title:
                    Text(state.item.tags.map((e) => "#$e").toList().join(" ")),
                dense: true,
              ),
            ListTile(title: Text("Subcategories"), dense: true),
            BlocBuilder<CategoryListPageBloc, CategoryListPageBlocState>(
                builder: (context, catListState) =>
                    catListState is CategoriesLoadSuccess
                        ? Builder(builder: (context) {
                            final ancestryGraph = <String, TreeNode<String>>{};
                            void recursivelyAddChildren(List<String> children) {
                              for (final id in children) {
                                ancestryGraph[id] =
                                    catListState.ancestryGraph[id]!;
                              }
                            }

                            for (final node in catListState
                                .ancestryGraph[state.id]!.children
                                .map((e) => catListState.ancestryGraph[e]!)) {
                              ancestryGraph[node.item] = TreeNode(
                                node.item,
                                children: node.children,
                                parent: null,
                              );
                              recursivelyAddChildren(node.children);
                            }

                            return CategoryListView(
                              ancestryGraph: ancestryGraph,
                              items: catListState.items,
                              markArchived: !state.item.isArchived,
                              onSelect: (id) => Navigator.pushNamed(
                                context,
                                CategoryDetailsPage.routeName,
                                arguments: id,
                              ),
                            );
                          })
                        : catListState is CategoriesLoading
                            ? Center(
                                child: CircularProgressIndicator(),
                              )
                            : throw Exception("Unhandled state: $catListState"))
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(
                  context, CategoryEditPage.routeName,
                  arguments: CategoryEditNewArgs(parent: state.id)),
              icon: Icon(Icons.add),
              label: Text("Subcategory"),
            ),
            // ...defaultActionButtons(context),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CategoryDetailsPageBloc, CategoryDetailsPageState>(
        builder: (context, state) {
          if (state is CategoryLoadSuccess) {
            return _showDetails(context, state);
          } else if (state is LoadingCategory) {
            return Scaffold(
              appBar: AppBar(
                title: const Text("Loading category..."),
              ),
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (state is CategoryNotFound) {
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
          } else {
            throw Exception("Unhandled state");
          }
        },
      );
}
