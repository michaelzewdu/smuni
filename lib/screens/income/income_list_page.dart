import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/widgets/income_list_view.dart';
import 'package:smuni/widgets/widgets.dart';

import 'income_edit_page.dart';

class IncomeListPage extends StatefulWidget {
  static const String routeName = "/incomeList";

  static Widget page() => BlocProvider(
        create: (context) => IncomeListPageBloc(
          context.read<IncomeRepository>(),
          context.read<OfflineIncomeRepository>(),
          context.read<AuthBloc>(),
        ),
        child: IncomeListPage(),
      );

  static Route route() => MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (context) => IncomeListPage.page(),
      );

  @override
  State<StatefulWidget> createState() => _IncomeListPageState();
}

class _IncomeListPageState extends State<IncomeListPage> {
  String? _selectedIncome;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text("Incomes"),
        ),
        body: BlocBuilder<IncomeListPageBloc, IncomeListPageBlocState>(
          builder: (context, state) {
            if (state is IncomesLoadSuccess) {
              return SingleChildScrollView(
                child: IncomeListView(
                  items: state.items,
                  onSelected: (id) => setState(() => _selectedIncome = id),
                  onEdit: (id) => Navigator.pushNamed(
                    context,
                    IncomeEditPage.routeName,
                    arguments: state.items[id],
                  ),
                  onDelete: (id) async {
                    final item = state.items[id]!;
                    final confirm = await showDialog<bool?>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm deletion'),
                        content: Text(
                          'Are you sure you want to delete entry ${item.name}?',
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Confirm'),
                          ),
                        ],
                      ),
                    );
                    if (confirm != null && confirm) {
                      context.read<IncomeListPageBloc>().add(DeleteIncome(id));
                    }
                  },
                ),
              );
            }
            return Center(child: CircularProgressIndicator.adaptive());
          },
        ),
        floatingActionButton: Visibility(
          visible: _selectedIncome == null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                onPressed: () =>
                    Navigator.pushNamed(context, IncomeEditPage.routeName),
                icon: Icon(Icons.add),
                label: Text("Income"),
              ),
              ...defaultActionButtons(context),
            ],
          ),
        ),
      );
}
