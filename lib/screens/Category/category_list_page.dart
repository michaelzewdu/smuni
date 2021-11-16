import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smuni/blocs/category_list_page.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/widgets/widgets.dart';

import '../../constants.dart';
import 'category_details_page.dart';
import 'category_edit_page.dart';

class CategoryListPage extends StatefulWidget {
  static const String routeName = "/categoryList";
  static const String routeNameArchivedOnly = "/categoryListArchivedOnly";

  static Route route() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) => page(),
    );
  }

  static Route routeArchivedOnly() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) => BlocProvider(
        create: (context) => CategoryListPageBloc(
          context.read<CategoryRepository>(),
          context.read<OfflineCategoryRepository>(),
          const LoadCategoriesFilter(
            includeActive: false,
            includeArchvied: true,
          ),
        ),
        child: CategoryListPage(
          showingArchivedOnly: true,
        ),
      ),
    );
  }

  static BlocProvider<CategoryListPageBloc> page() {
    return BlocProvider(
      create: (context) => CategoryListPageBloc(
        context.read<CategoryRepository>(),
        context.read<OfflineCategoryRepository>(),
      ),
      child: CategoryListPage(),
    );
  }

  final bool showingArchivedOnly;
  const CategoryListPage({Key? key, this.showingArchivedOnly = false})
      : super(key: key);
  @override
  State<StatefulWidget> createState() => _CategoryListPageState();
}

enum CategoryListActions { archived }

class _CategoryListPageState extends State<CategoryListPage> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: semuni50,
          foregroundColor: Colors.black,
          shadowColor: Colors.transparent,
          title: widget.showingArchivedOnly
              ? const Text("Category Trash")
              : const Text("Categories"),
          actions: [
            if (!widget.showingArchivedOnly)
              PopupMenuButton<CategoryListActions>(
                  onSelected: (CategoryListActions action) {
                    if (action == CategoryListActions.archived) {
                      Navigator.pushNamed(
                          context, CategoryListPage.routeNameArchivedOnly);
                    }
                  },
                  itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: CategoryListActions.archived,
                            child: Text('Trash'))
                      ])
          ],
        ),
        body: BlocBuilder<CategoryListPageBloc, CategoryListPageBlocState>(
          builder: (context, state) {
            if (state is CategoriesLoadSuccess) {
              return Column(
                children: [
                  /* if (!widget.showingArchivedOnly)
                    ListTile(
                      title: Text("Trash"),
                      dense: true,
                      onTap: () => Navigator.pushNamed(
                          context, CategoryListPage.routeNameArchivedOnly),
                    ), */
                  Expanded(
                    child: CategoryListView(
                      state: state,
                      markArchived: !widget.showingArchivedOnly,
                      onSelect: (id) => Navigator.pushNamed(
                        context,
                        CategoryDetailsPage.routeName,
                        arguments: id,
                      ),
                    ),
                  ),
                ],
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
