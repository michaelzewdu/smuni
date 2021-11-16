export "package:smuni_api_client/src/models.dart";

class Preferences {
  final String miscCategory;
  final String? mainBudget;
  final bool? syncPending;

  Preferences({required this.miscCategory, this.mainBudget, this.syncPending});
  factory Preferences.from(
    Preferences other, {
    String? miscCategory,
    String? mainBudget,
    bool? syncPending,
  }) =>
      Preferences(
        miscCategory: miscCategory ?? other.miscCategory,
        mainBudget: mainBudget ?? other.mainBudget,
        syncPending: syncPending ?? other.syncPending,
      );
}
