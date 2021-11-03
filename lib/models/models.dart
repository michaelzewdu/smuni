export "package:smuni_api_client/src/models.dart";

class Preferences {
  final String? mainBudget;
  final bool? syncPending;

  Preferences({this.mainBudget, this.syncPending});
  factory Preferences.from(
    Preferences other, {
    String? mainBudget,
    bool? syncPending,
  }) =>
      Preferences(
        mainBudget: mainBudget ?? other.mainBudget,
        syncPending: syncPending ?? other.syncPending,
      );
}
