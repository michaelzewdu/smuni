import 'dart:collection';

class User {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String firebaseId;
  final String username;
  final String? email;
  final String? phoneNumber;
  final String? pictureURL;
  final String? mainBudget;

  User({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.firebaseId,
    required this.username,
    this.email,
    this.phoneNumber,
    this.pictureURL,
    this.mainBudget,
  });

  Map<String, dynamic> toJSON() => {
        "_id": id,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
        "firebaseId": firebaseId,
        "username": username,
        "email": email,
        "phoneNumber": phoneNumber,
        "pictureURL": pictureURL,
        "mainBudget": mainBudget,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: checkedConvert(json, "_id", (v) => v as String),
        createdAt: checkedConvert(json, "createdAt", (v) => DateTime.parse(v)),
        updatedAt: checkedConvert(json, "updatedAt", (v) => DateTime.parse(v)),
        firebaseId: checkedConvert(json, "firebaseId", (v) => v as String),
        username: checkedConvert(json, "username", (v) => v as String),
        email: checkedConvert(json, "email", (v) => v as String?),
        phoneNumber: checkedConvert(json, "phoneNumber", (v) => v as String?),
        pictureURL: checkedConvert(json, "pictureURL", (v) => v as String?),
        mainBudget: checkedConvert(json, "mainBudget", (v) => v as String?),
      );

  factory User.from(
    User other, {
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? firebaseId,
    String? username,
    String? email,
    String? phoneNumber,
    String? pictureURL,
    String? mainBudget,
  }) =>
      User(
        id: id ?? other.id,
        createdAt: createdAt ?? other.createdAt,
        updatedAt: updatedAt ?? other.updatedAt,
        firebaseId: firebaseId ?? other.firebaseId,
        username: username ?? other.username,
        email: email ?? other.email,
        phoneNumber: phoneNumber ?? other.phoneNumber,
        pictureURL: pictureURL ?? other.pictureURL,
        mainBudget: mainBudget ?? other.mainBudget,
      );
}

class UserDenorm extends User {
  final List<Budget> budgets;
  final List<Expense> expenses;
  final List<Category> categories;

  UserDenorm({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String firebaseId,
    required String username,
    String? email,
    String? phoneNumber,
    String? pictureURL,
    String? mainBudget,
    required this.budgets,
    required this.expenses,
    required this.categories,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
          firebaseId: firebaseId,
          username: username,
          email: email,
          phoneNumber: phoneNumber,
          pictureURL: pictureURL,
          mainBudget: mainBudget,
        );

  @override
  Map<String, dynamic> toJSON() => {
        ...super.toJSON(),
        "budgets": budgets.map((e) => e.toJSON()),
        "categories": categories.map((c) => c.toJSON()),
        "expenses": expenses.map((e) => e.toJSON()),
      };

  factory UserDenorm.fromJson(Map<String, dynamic> json) {
    final user = User.fromJson(json);
    return UserDenorm(
      id: user.id,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      firebaseId: user.firebaseId,
      username: user.username,
      email: user.email,
      phoneNumber: user.phoneNumber,
      pictureURL: user.pictureURL,
      mainBudget: user.mainBudget,
      budgets: checkedConvert(
        json,
        "budgets",
        (v) => v == null
            ? []
            : checkedConvertArray(
                v as List<dynamic>, (_, v) => Budget.fromJson(v)),
      ),
      expenses: checkedConvert(
        json,
        "expenses",
        (v) => v == null
            ? []
            : checkedConvertArray(
                v as List<dynamic>, (_, v) => Expense.fromJson(v)),
      ),
      categories: checkedConvert(
        json,
        "categories",
        (v) => v == null
            ? []
            : checkedConvertArray(
                v as List<dynamic>, (_, v) => Category.fromJson(v)),
      ),
    );
  }

  factory UserDenorm.from(
    UserDenorm other, {
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? firebaseId,
    String? username,
    String? email,
    String? phoneNumber,
    String? pictureURL,
    String? mainBudget,
    List<Budget>? budgets,
    List<Expense>? expenses,
    List<Category>? categories,
  }) =>
      UserDenorm(
        id: id ?? other.id,
        createdAt: createdAt ?? other.createdAt,
        updatedAt: updatedAt ?? other.updatedAt,
        firebaseId: firebaseId ?? other.firebaseId,
        username: username ?? other.username,
        email: email ?? other.email,
        phoneNumber: phoneNumber ?? other.phoneNumber,
        pictureURL: pictureURL ?? other.pictureURL,
        mainBudget: mainBudget ?? other.mainBudget,
        budgets: budgets ?? other.budgets,
        expenses: expenses ?? other.expenses,
        categories: categories ?? other.categories,
      );
}

enum FrequencyKind { oneTime, recurring }

abstract class Frequency {
  final FrequencyKind kind;

  const Frequency(this.kind);
  Map<String, dynamic> toJSON();

  factory Frequency.fromJson(Map<String, dynamic> json) {
    var kind = checkedConvert(
        json, "kind", (v) => enumFromString(FrequencyKind.values, v));
    switch (kind) {
      case FrequencyKind.oneTime:
        return OneTime();
      case FrequencyKind.recurring:
        return Recurring(
            checkedConvert(json, "recurringIntervalSecs", (v) => v as int));
    }
  }
  @override
  String toString() => "${runtimeType.toString()}  { kind: $kind }";
}

class OneTime extends Frequency {
  const OneTime() : super(FrequencyKind.oneTime);
  @override
  Map<String, dynamic> toJSON() => {
        "kind": kind.toString().split(".")[1],
      };

  @override
  bool operator ==(other) => other is OneTime;

  @override
  int get hashCode => 0;
}

class Recurring extends Frequency {
  final int recurringIntervalSecs;
  Recurring(this.recurringIntervalSecs) : super(FrequencyKind.oneTime);

  @override
  Map<String, dynamic> toJSON() => {
        "kind": kind.toString().split(".")[1],
        "recurringIntervalSecs": recurringIntervalSecs
      };

  @override
  String toString() =>
      "${runtimeType.toString()}  { recurringIntervalSecs: $recurringIntervalSecs }";
  @override
  bool operator ==(other) =>
      other is Recurring &&
      recurringIntervalSecs == other.recurringIntervalSecs;

  @override
  int get hashCode => recurringIntervalSecs;
}

class MonetaryAmount {
  final String currency;
  final int amount;

  const MonetaryAmount({required this.currency, required this.amount});

  Map<String, dynamic> toJSON() => {"currency": currency, "amount": amount};
  factory MonetaryAmount.fromJson(Map<String, dynamic> json) => MonetaryAmount(
        currency: checkedConvert(json, "currency", (v) => v as String),
        amount: checkedConvert(json, "amount", (v) => v as int),
      );
  int get wholes => (amount / 100).truncate();
  int get cents => (amount % 100);

  @override
  bool operator ==(other) =>
      other is MonetaryAmount &&
      currency == other.currency &&
      amount == other.amount;

  @override
  int get hashCode => amount ^ currency.hashCode;
}

class Budget {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final MonetaryAmount allocatedAmount;
  final Frequency frequency;
  final Map<String, int> categoryAllocations;
  Budget({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.allocatedAmount,
    required this.frequency,
    required this.categoryAllocations,
  });

  Map<String, dynamic> toJSON() => {
        "_id": id,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
        "name": name,
        "startTime": startTime.toUtc().toString(),
        "endTime": endTime.toUtc().toString(),
        "allocatedAmount": allocatedAmount.toJSON(),
        "frequency": frequency.toJSON(),
        "categoryAllocations": HashMap.from(categoryAllocations),
      };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        id: checkedConvert(json, "_id", (v) => v as String),
        createdAt: checkedConvert(json, "createdAt", (v) => DateTime.parse(v)),
        updatedAt: checkedConvert(json, "updatedAt", (v) => DateTime.parse(v)),
        name: checkedConvert(json, "name", (v) => v as String),
        startTime: checkedConvert(json, "startTime", (v) => DateTime.parse(v)),
        endTime: checkedConvert(json, "endTime", (v) => DateTime.parse(v)),
        frequency:
            checkedConvert(json, "frequency", (v) => Frequency.fromJson(v)),
        allocatedAmount: checkedConvert(
            json, "allocatedAmount", (v) => MonetaryAmount.fromJson(v)),
        categoryAllocations: checkedConvert(
          json,
          "categoryAllocation",
          (v) => v == null
              ? {}
              : checkedConvertMap(
                  v as Map<String, dynamic>, (_, v) => v as int),
        ),
      );
  factory Budget.from(
    Budget other, {
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    MonetaryAmount? allocatedAmount,
    Frequency? frequency,
    Map<String, int>? categoryAllocation,
  }) =>
      Budget(
        id: id ?? other.id,
        createdAt: createdAt ?? other.createdAt,
        updatedAt: updatedAt ?? other.updatedAt,
        name: name ?? other.name,
        startTime: startTime ?? other.startTime,
        endTime: endTime ?? other.endTime,
        allocatedAmount: allocatedAmount ?? other.allocatedAmount,
        frequency: frequency ?? other.frequency,
        categoryAllocations: categoryAllocation ?? other.categoryAllocations,
      );
}

class Category {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final String? parentId;
  final List<String> tags;
  Category({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    this.parentId,
    required this.tags,
  });

  Map<String, dynamic> toJSON() => {
        "_id": id,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
        "name": name,
        "parentId": parentId,
        "tags": tags,
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: checkedConvert(json, "_id", (v) => v as String),
        createdAt: checkedConvert(json, "createdAt", (v) => DateTime.parse(v)),
        updatedAt: checkedConvert(json, "updatedAt", (v) => DateTime.parse(v)),
        parentId: checkedConvert(
            json,
            "parentCategory",
            (v) => v == null
                ? null
                : checkedConvert(v, "_id", (v) => v as String)),
        name: checkedConvert(json, "name", (v) => v as String),
        tags: checkedConvert(
            json,
            "tags",
            (v) => v == null
                ? []
                : checkedConvertArray(
                    v as List<dynamic>, (_, v) => v as String)),
      );
  factory Category.from(
    Category other, {
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    MonetaryAmount? allocatedAmount,
    String? parentId,
    List<String>? tags,
  }) =>
      Category(
        id: id ?? other.id,
        createdAt: createdAt ?? other.createdAt,
        updatedAt: updatedAt ?? other.updatedAt,
        name: name ?? other.name,
        parentId: parentId ?? other.parentId,
        tags: tags ?? other.tags,
      );
}

class Expense {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final MonetaryAmount amount;
  final String categoryId;
  final String budgetId;
  Expense({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.categoryId,
    required this.budgetId,
    required this.amount,
  });

  Map<String, dynamic> toJSON() => {
        "_id": id,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
        "name": name,
        "categoryId": categoryId,
        "budgetId": budgetId,
        "amount": amount.toJSON(),
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: checkedConvert(json, "_id", (v) => v as String),
        createdAt: checkedConvert(json, "createdAt", (v) => DateTime.parse(v)),
        updatedAt: checkedConvert(json, "updatedAt", (v) => DateTime.parse(v)),
        name: checkedConvert(json, "name", (v) => v as String),
        categoryId: checkedConvert(json, "categoryId", (v) => v as String),
        budgetId: checkedConvert(json, "budgetId", (v) => v as String),
        amount:
            checkedConvert(json, "amount", (v) => MonetaryAmount.fromJson(v)),
      );

  factory Expense.from(
    Expense other, {
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    String? categoryId,
    String? budgetId,
    MonetaryAmount? amount,
  }) =>
      Expense(
        id: id ?? other.id,
        createdAt: createdAt ?? other.createdAt,
        updatedAt: updatedAt ?? other.updatedAt,
        name: name ?? other.name,
        categoryId: categoryId ?? other.categoryId,
        budgetId: budgetId ?? other.budgetId,
        amount: amount ?? other.amount,
      );
}

T enumFromString<T>(Iterable<T> values, String value) {
  return values.firstWhere(
    (type) =>
        type.toString() == value ||
        type.toString().split(".").last.toLowerCase() == value.toLowerCase(),
  );
}

T checkedConvert<T>(
  Map<String, dynamic> json,
  String prop,
  T Function(dynamic) extract,
  // {bool checkForNull = true}
) {
  var value = json[prop];
  /*if (checkForNull) {
    if (value == null) {
      throw new Exception("value at prop $prop is null");
    }
  }*/
  return extract(value);
}

List<T> checkedConvertArray<T>(
  List<dynamic> json,
  T Function(int, dynamic) extract,
  // {bool checkForNull = true}
) {
  var index = -1;
  return json.map((e) {
    index += 1;
    return extract(index, e);
  }).toList();
}

Map<String, T> checkedConvertMap<T>(
  Map<String, dynamic> json,
  T Function(String, dynamic) extract,
  // {bool checkForNull = true}
) =>
    HashMap.fromIterable(json.entries.map((e) => extract(e.key, e.value)));
