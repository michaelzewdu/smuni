import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';

import 'category_edit_page.dart';

class CategoryDetailsPage extends StatelessWidget {
  static const String routeName = "categoryDetails";

  static Route route(String id) => MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (context) => BlocProvider(
          create: (context) => DetailsPageBloc<String, Category>(
              context.read<CategoryRepository>(), id),
          child: CategoryDetailsPage(),
        ),
      );

  const CategoryDetailsPage({Key? key}) : super(key: key);

  Widget _showDetails(
    BuildContext context,
    LoadSuccess<String, Category> state,
  ) =>
      Scaffold(
        appBar: AppBar(
          title: Text(state.item.name),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                CategoryEditPage.routeName,
                arguments: state.item,
              ),
              child: const Text("Edit"),
            ),
            ElevatedButton(
              onPressed: () => showDialog<bool?>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm deletion'),
                  content: Text(
                      'Are you sure you want to delete entry ${state.item.name}?\nTODO: decide on how deletion works'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      /* onPressed: () {
                        Navigator.pop(context, true);
                      }, */
                      onPressed: null,
                      child: const Text('TODO'),
                    ),
                  ],
                ),
              ).then(
                (confirm) {
                  if (confirm != null && confirm) {
                    context
                        .read<DetailsPageBloc<String, Category>>()
                        .add(DeleteItem());
                    Navigator.pop(context);
                  }
                },
              ),
              child: const Text("Delete"),
            )
          ],
        ),
        body: Column(
          children: <Widget>[
            Text(state.item.name),
            Text("id: ${state.item.id}"),
            Text("tags: ${state.item.tags}"),
            Text("createdAt: ${state.item.createdAt}"),
            Text("updatedAt: ${state.item.updatedAt}"),
          ],
        ),
      );
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DetailsPageBloc<String, Category>, DetailsPageState>(
        builder: (context, state) {
          if (state is LoadSuccess<String, Category>) {
            return _showDetails(context, state);
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
