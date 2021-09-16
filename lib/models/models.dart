class User {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String firebaseId;
  final String username;
  final String email;
  final String phoneNumber;
  final String? pictureURL;
  final List<Budget> budgets;
  final List<Expense> expenses;

  User({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.firebaseId,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.pictureURL,
    required this.budgets,
    required this.expenses,
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
        "budgets": budgets.map((e) => e.toJSON()),
        "expenses": expenses.map((e) => e.toJSON()),
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: checkedConvert(json, "_id", (v) => v as String),
        createdAt: checkedConvert(json, "createdAt", (v) => DateTime.parse(v)),
        updatedAt: checkedConvert(json, "updatedAt", (v) => DateTime.parse(v)),
        firebaseId: checkedConvert(json, "firebaseId", (v) => v as String),
        username: checkedConvert(json, "username", (v) => v as String),
        email: checkedConvert(json, "email", (v) => v as String),
        phoneNumber: checkedConvert(json, "phoneNumber", (v) => v as String),
        pictureURL: checkedConvert(json, "pictureURL", (v) => v as String?),
        budgets: checkedConvert(
            json,
            "budgets",
            (v) => v == null
                ? []
                : checkedConvertArray(
                    v as List<dynamic>, (_, v) => Budget.fromJson(v))),
        expenses: checkedConvert(
            json,
            "expenses",
            (v) => v == null
                ? []
                : checkedConvertArray(
                    v as List<dynamic>, (_, v) => Expense.fromJson(v))),
      );
}

enum FrequencyKind { OneTime, Recurring }

abstract class Frequency {
  final FrequencyKind kind;

  const Frequency(this.kind);
  Map<String, dynamic> toJSON();

  factory Frequency.fromJson(Map<String, dynamic> json) {
    var kind = checkedConvert(
        json, "kind", (v) => enumFromString(FrequencyKind.values, v));
    switch (kind) {
      case FrequencyKind.OneTime:
        return OneTime();
      case FrequencyKind.Recurring:
        return Recurring(
            checkedConvert(json, "recurringIntervalSecs", (v) => v as int));
    }
  }
}

class OneTime extends Frequency {
  const OneTime() : super(FrequencyKind.OneTime);
  Map<String, dynamic> toJSON() => {
        "kind": kind,
      };
}

class Recurring extends Frequency {
  final int recurringIntervalSecs;
  Recurring(this.recurringIntervalSecs) : super(FrequencyKind.OneTime);

  Map<String, dynamic> toJSON() =>
      {"kind": kind, "recurringIntervalSecs": recurringIntervalSecs};
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
  final List<Category> categories;
  Budget({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.allocatedAmount,
    required this.frequency,
    required this.categories,
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
        "categories": categories.map((c) => c.toJSON()),
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
        categories: checkedConvert(
            json,
            "categories",
            (v) => v == null
                ? []
                : checkedConvertArray(
                    v as List<dynamic>, (_, v) => Category.fromJson(v))),
      );
}

class Category {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final MonetaryAmount allocatedAmount;
  final String? parentId;
  final List<String> tags;
  Category({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.parentId,
    required this.allocatedAmount,
    required this.tags,
  });

  Map<String, dynamic> toJSON() => {
        "_id": id,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
        "name": name,
        "parentId": parentId,
        "allocatedAmount": allocatedAmount.toJSON(),
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
        allocatedAmount: checkedConvert(
            json, "allocatedAmount", (v) => MonetaryAmount.fromJson(v)),
        tags: checkedConvert(
            json,
            "tags",
            (v) => v == null
                ? []
                : checkedConvertArray(
                    v as List<dynamic>, (_, v) => v as String)),
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

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: checkedConvert(json, "_id", (v) => v as String),
      createdAt: checkedConvert(json, "createdAt", (v) => DateTime.parse(v)),
      updatedAt: checkedConvert(json, "updatedAt", (v) => DateTime.parse(v)),
      name: checkedConvert(json, "name", (v) => v as String),
      categoryId: checkedConvert(json, "category",
          (v) => checkedConvert(v, "_id", (v) => v as String)),
      budgetId: checkedConvert(json, "category",
          (v) => checkedConvert(v, "budgetId", (v) => v as String)),
      amount: checkedConvert(json, "amount", (v) => MonetaryAmount.fromJson(v)),
    );
  }

  factory Expense.from(
    Expense other, {
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    String? categoryId,
    String? budgetId,
    MonetaryAmount? amount,
  }) {
    return Expense(
      id: id ?? other.id,
      createdAt: createdAt ?? other.createdAt,
      updatedAt: updatedAt ?? other.updatedAt,
      name: name ?? other.name,
      categoryId: categoryId ?? other.categoryId,
      budgetId: budgetId ?? other.budgetId,
      amount: amount ?? other.amount,
    );
  }
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
