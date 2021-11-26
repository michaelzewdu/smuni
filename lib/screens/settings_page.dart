import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/models/models.dart';
import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/utilities.dart';
import 'package:smuni/widgets/widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  static const String routeName = '/settings';

  static Route route() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) => MultiBlocProvider(providers: [
        BlocProvider(
          create: (context) => BudgetListPageBloc(
            context.read<BudgetRepository>(),
            context.read<OfflineBudgetRepository>(),
          ),
        ),
        BlocProvider(
          create: (context) => CategoryListPageBloc(
              context.read<CategoryRepository>(),
              context.read<OfflineCategoryRepository>(),
              LoadCategoriesFilter(includeActive: true, includeArchvied: true)),
        )
      ], child: SettingsPage()),
    );
  }

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  var _awaitingOp = false;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          shadowColor: Colors.transparent,
          centerTitle: true,
          title: Text(
            'Kamasio',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        body: BlocBuilder<PreferencesBloc, PreferencesBlocState>(
            builder: (context, prefState) => prefState is PreferencesLoadSuccess
                ? Column(
                    // crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BlocBuilder<BudgetListPageBloc, BudgetListPageBlocState>(
                        builder: (context, state) => state is BudgetsLoadSuccess
                            ? Builder(builder: (context) {
                                final mainBudgetId = context
                                    .read<PreferencesBloc>()
                                    .preferencesLoadSuccessState()
                                    .preferences
                                    .mainBudget;
                                return ListTile(
                                  leading: Text("Main budget"),
                                  title: mainBudgetId != null
                                      ? Text(state.items[mainBudgetId]!.name)
                                      : Text("Not set."),
                                  trailing: TextButton(
                                    onPressed: () =>
                                        showMainBudgetSelectorModal(
                                            context,
                                            (newMainBudget,
                                                    {onSuccess, onError}) =>
                                                context
                                                    .read<PreferencesBloc>()
                                                    .add(
                                                      UpdatePreferences(
                                                        Preferences.from(
                                                          prefState.preferences,
                                                          mainBudget:
                                                              newMainBudget,
                                                        ),
                                                        onSuccess: () {
                                                          onSuccess?.call();
                                                          setState(() {});
                                                        },
                                                        onError: onError,
                                                      ),
                                                    ),
                                            initialSelection: mainBudgetId),
                                    child: Text("Change"),
                                  ),
                                );
                              })
                            : state is BudgetsLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : throw Exception("Unhandled state: $state"),
                      ),
                      BlocBuilder<CategoryListPageBloc,
                          CategoryListPageBlocState>(
                        builder: (context, state) => state
                                is CategoriesLoadSuccess
                            ? Builder(builder: (context) {
                                final miscCategoryId = context
                                    .read<PreferencesBloc>()
                                    .preferencesLoadSuccessState()
                                    .preferences
                                    .miscCategory;
                                return ListTile(
                                  leading: Text("Misc category"),
                                  title:
                                      Text(state.items[miscCategoryId]!.name),
                                  trailing: TextButton(
                                    onPressed: () =>
                                        showMiscCategorySelectorModal(
                                      context,
                                      (newMiscCategory, {onSuccess, onError}) =>
                                          context.read<PreferencesBloc>().add(
                                                UpdatePreferences(
                                                  Preferences.from(
                                                    prefState.preferences,
                                                    miscCategory:
                                                        newMiscCategory,
                                                  ),
                                                  onSuccess: () {
                                                    onSuccess?.call();
                                                    setState(() {});
                                                  },
                                                  onError: onError,
                                                ),
                                              ),
                                      initalSelection: miscCategoryId,
                                    ),
                                    child: Text("Change"),
                                  ),
                                );
                              })
                            : state is CategoriesLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : throw Exception("Unhandled state: $state"),
                      ),
                      ListTile(
                        title: Text("Kamasio"),
                        trailing: Text("0.0.1-alpha"),
                        onTap: () => showAboutDialog(
                          context: context,
                          applicationName: "Smuni",
                          applicationVersion: "0.0.1-alpha",
                          children: [Text("TODO")],
                        ),
                      ),
                      !_awaitingOp
                          ? ElevatedButton(
                              onPressed: () {
                                setState(() => _awaitingOp = true);
                                context.read<SyncBloc>().add(TrySync(
                                      onSuccess: () {
                                        setState(() => _awaitingOp = false);
                                      },
                                      onError: (err) {
                                        setState(() => _awaitingOp = false);

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: err is ConnectionException
                                                ? Text('Connection Failed')
                                                : err is ConnectionException
                                                    ? Text('Not Signed In')
                                                    : Text(
                                                        'Unknown Error Occured'),
                                            behavior: SnackBarBehavior.floating,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                    ));
                              },
                              child: const Text("Sync"),
                            )
                          : const CircularProgressIndicator(),
                    ],
                  )
                : prefState is PreferencesLoading
                    ? const Center(child: CircularProgressIndicator())
                    : throw Exception("unexpected state")),
      );
}
