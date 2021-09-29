import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/category_list_page.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';

import 'category_details_page.dart';
import 'category_edit_page.dart';

class CategoryListPage extends StatefulWidget {
  static const String routeName = "/categoryList";

  static Route route() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) => BlocProvider(
        create: (context) =>
            CategoryListPageBloc(context.read<CategoryRepository>()),
        child: CategoryListPage(),
      ),
    );
  }

  @override
  State<StatefulWidget> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text("Categories"),
        ),
        body: BlocBuilder<CategoryListPageBloc, CategoryListPageBlocState>(
          builder: (context, state) {
            if (state is CategoriesLoadSuccess) {
              final items = state.items;
              final keys = items.keys;
              return items.isNotEmpty
                  ? ListView.builder(
                      itemCount: keys.length,
                      itemBuilder: (context, index) {
                        final item = items[keys.elementAt(index)]!;
                        return ListTile(
                          title: Text(item.name),
                          subtitle: Text(
                            "${monthNames[item.createdAt.month]} ${item.createdAt.day} ${item.createdAt.year}",
                          ),
                          trailing: Text(
                            "${item.allocatedAmount.currency} ${item.allocatedAmount.amount / 100}",
                          ),
                          onTap: () => Navigator.pushNamed(
                            context,
                            CategoryDetailsPage.routeName,
                            arguments: item.id,
                          ),
                        );
                      },
                    )
                  : Center(child: const Text("No categories."));
            }
            return Center(child: CircularProgressIndicator.adaptive());
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(
            context,
            CategoryEditPage.routeName,
          ),
          child: Icon(Icons.add),
          tooltip: "Add",
        ),
      );
}
