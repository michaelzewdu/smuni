import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/category_list_page.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/widgets/category_list_view.dart';

import 'category_details_page.dart';
import 'category_edit_page.dart';

class CategoryListPage extends StatefulWidget {
  static const String routeName = "/categoryList";

  static Route route() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) => page(),
    );
  }

  static BlocProvider<CategoryListPageBloc> page() {
    return BlocProvider(
      create: (context) =>
          CategoryListPageBloc(context.read<CategoryRepository>()),
      child: CategoryListPage(),
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
              return CategoryListView(
                state: state,
                onSelect: (id) => Navigator.pushNamed(
                  context,
                  CategoryDetailsPage.routeName,
                  arguments: id,
                ),
              );
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
