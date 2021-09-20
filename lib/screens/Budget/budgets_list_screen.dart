import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smuni/blocs/blocs.dart';

class BudgetListPage extends StatelessWidget {
  const BudgetListPage({Key? key}) : super(key: key);

  static const String routeName = '/budgetListScreen';

  static Route route() {
    return MaterialPageRoute(
        settings: RouteSettings(name: routeName),
        builder: (context) => BudgetListPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budgets'),
      ),
      body: BlocConsumer<BudgetsBloc, BudgetsBlocState>(
          builder: (context, state) {
        if (state is BudgetsLoading) {
          return CupertinoActivityIndicator(
            animating: true,
            radius: 76,
          );
        }
        if (state is BudgetsLoadSuccess) {
          final keys = state.items.keys;
          return ListView.builder(
            itemCount: state.items.length,
            itemBuilder: (BuildContext context, int index) {
              final budgetItem = state.items[keys.elementAt(index)];
              return ListTile(
                title: Text(
                  '${budgetItem!.name}',
                  textScaleFactor: 1.5,
                ),
                trailing: Text(
                  '${budgetItem.allocatedAmount.amount}',
                  textScaleFactor: 1.5,
                ),
                subtitle: Row(children: [
                  Text(
                      '${budgetItem.startTime.month} ${budgetItem.startTime.day} ${budgetItem.startTime.year}  '),
                  Text(
                      'to  ${budgetItem.endTime.month} ${budgetItem.endTime.day} ${budgetItem.endTime.year}')
                ]),
                onTap: () {},
              );
            },
          );
        } else {
          return Text('An error occurred. Try again in a bit.');
        }
      }, listener: (context, state) {
        //  print('');
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {  },
        child: Icon(
          Icons.add
        ),
      ),
    );
  }
}
