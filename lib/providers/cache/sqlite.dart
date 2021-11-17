// TODO: optimize me

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:smuni/models/models.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'cache.dart';

const _serverVersionPrefix = "serverVersion";

Future<sqflite.Database> initDb() async {
  var databasesPath = await sqflite.getDatabasesPath();
  final path = databasesPath + "/main.db";
  {
    final dir = Directory(databasesPath);
    if (!(await dir.exists())) await dir.create();
  }

  // await sqflite.deleteDatabase(path);

  final db = await sqflite.openDatabase(
    path,
    // path,
    version: 1,
    onCreate: (db, version) async {
      await db.transaction(migrateV1);
      // in case they skipped sign up, create a misc category in cache
      SqliteCategoryCache(db).setItem(
        "000000000000000000000000",
        Category(
          id: "000000000000000000000000",
          version: -1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          name: "Misc",
          tags: ["misc"],
          isServerVersion: false,
        ),
      );
    },
  );

  return db;
}

Future<void> migrateV1(sqflite.Transaction txn) async {
  await txn.execute('''
create table users ( 
  username text primary key,
  _id text unique not null,
  firebaseId text unique not null,
  email text unique,
  phoneNumber text unique,
  pictureURL text unique,
  mainBudget text,
  miscCategory text,
  version integer not null,
  createdAt integer not null,
  updatedAt integer not null
)''');

  final budgetRows = """
  ( 
  _id text primary key,
  name text not null,
  startTime integer not null,
  endTime integer not null,
  allocatedAmountCurrency text not null,
  allocatedAmountValue integer not null,
  frequencyKind text not null,
  frequencyRecurringIntervalSecs integer,
  categoryAllocations text not null,
  archivedAt integer,
  version integer not null,
  isServerVersion integer not null,
  createdAt integer not null,
  updatedAt integer not null)""";
  await txn.execute("create table budgets $budgetRows");
  await txn.execute("create table ${_serverVersionPrefix}Budgets $budgetRows");
  await txn.execute('''create table removedBudgets (_id text primary key)''');

  final categoryRows = '''( 
  _id text primary key,
  name text not null,
  parentId text,
  tags text not null,
  archivedAt integer,
  version integer not null,
  isServerVersion integer not null,
  createdAt integer not null,
  updatedAt integer not null)''';
  await txn.execute("create table categories $categoryRows");
  await txn
      .execute("create table ${_serverVersionPrefix}Categories $categoryRows");
  await txn
      .execute('''create table removedCategories (_id text primary key)''');

  final expenseRows = '''( 
  _id text primary key,
  name text not null,
  timestamp integer not null,
  amountCurrency text not null,
  amountValue integer not null,
  categoryId text not null,
  budgetId text not null,
  version integer not null,
  isServerVersion integer not null,
  createdAt integer not null,
  updatedAt integer not null)''';
  await txn.execute("create table expenses $expenseRows");
  await txn
      .execute("create table ${_serverVersionPrefix}Expenses $expenseRows");
  await txn.execute('''create table removedExpenses (_id text primary key)''');

  final incomeRows = '''( 
  _id text primary key,
  name text not null,
  timestamp integer not null,
  amountCurrency text not null,
  amountValue integer not null,
  frequencyKind text not null,
  frequencyRecurringIntervalSecs integer,
  version integer not null,
  isServerVersion integer not null,
  createdAt integer not null,
  updatedAt integer not null)''';
  await txn.execute("create table incomes $incomeRows");
  await txn.execute("create table ${_serverVersionPrefix}Incomes $incomeRows");
  await txn.execute('''create table removedIncomes (_id text primary key)''');

  await txn.execute('''
create table stuff ( 
  key text primary key,
  value text key not null)
''');
}

class _StuffCache {
  final sqflite.Database db;

  _StuffCache(this.db);

  Future<String?> getStuff(String key) async {
    List<Map<String, Object?>> maps = await db.query("stuff",
        columns: ["value"], where: "key = ?", whereArgs: [key]);
    if (maps.isNotEmpty) {
      return (maps.first as dynamic)["value"];
    }
    return null;
  }

  Future<void> setStuff(String key, String value) async {
    await db.insert(
      "stuff",
      {
        "key": key,
        "value": value,
      },
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<void> clearStuff(
    String key,
  ) async {
    await db.delete(
      "stuff",
      where: 'key = ?',
      whereArgs: [key],
    );
  }
}

class AuthTokenCache {
  final _StuffCache _stuffCache;

  AuthTokenCache(sqflite.Database db) : _stuffCache = _StuffCache(db);

  Future<String?> getAccessToken() => _stuffCache.getStuff("accessToken");
  Future<void> setAccessToken(String token) =>
      _stuffCache.setStuff("accessToken", token);
  Future<void> clearAccessToken() => _stuffCache.clearStuff("accessToken");

  Future<String?> getRefreshToken() => _stuffCache.getStuff("refreshToken");
  Future<void> setRefreshToken(String token) =>
      _stuffCache.setStuff("refreshToken", token);
  Future<void> clearRefreshToken() => _stuffCache.clearStuff("refreshToken");

  Future<String?> getUsername() => _stuffCache.getStuff("loggedInUsername");
  Future<void> setUsername(String token) =>
      _stuffCache.setStuff("loggedInUsername", token);
  Future<void> clearUsername() => _stuffCache.clearStuff("loggedInUsername");
}

class PreferencesCache {
  final _StuffCache _stuffCache;

  PreferencesCache(sqflite.Database db) : _stuffCache = _StuffCache(db);

  Future<Preferences> getPreferences() async => Preferences(
        miscCategory: await getMiscCategory(),
        mainBudget: await getMainBudget(),
        syncPending: await getSyncPending(),
      );

  Future<String?> getMainBudget() => _stuffCache.getStuff("mainBudget");
  Future<void> setMainBudget(String token) =>
      _stuffCache.setStuff("mainBudget", token);
  Future<void> clearMainBudget() => _stuffCache.clearStuff("mainBudget");

  Future<String> getMiscCategory() async {
    final id = await _stuffCache.getStuff("miscCategory");
    if (id == null) {
      await setMiscCategory("000000000000000000000000");
      return "000000000000000000000000";
    }
    return id;
  }

  Future<void> setMiscCategory(String token) =>
      _stuffCache.setStuff("miscCategory", token);
  Future<void> clearMiscCategory() => _stuffCache.clearStuff("miscCategory");

  Future<bool?> getSyncPending() async {
    final pending = await _stuffCache.getStuff("syncPending");
    if (pending == null) return null;
    return pending == "true";
  }

  Future<void> setSyncPending(bool pending) =>
      _stuffCache.setStuff("syncPending", pending ? "true" : "false");
  Future<void> clearSyncPending() => _stuffCache.clearStuff("syncPending");
}

class _SqliteCache<Identifier, Item> extends Cache<Identifier, Item> {
  final sqflite.Database db;
  String tableName;
  final String primaryColumnName;
  final String? defaultOrderColumn;
  final List<String> columns;
  final Map<String, dynamic> Function(Item) toMap;
  final Item Function(Map<String, dynamic>) fromMap;

  _SqliteCache(
    this.db, {
    required this.tableName,
    required this.primaryColumnName,
    required this.columns,
    required this.toMap,
    required this.fromMap,
    this.defaultOrderColumn,
  });

  @override
  Future<Item?> getItem(Identifier id) async {
    List<Map<String, Object?>> maps = await db.query(tableName,
        columns: columns, where: '$primaryColumnName = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<Map<Identifier, Item>> getItems() async {
    List<Map<String, Object?>> maps = await db.query(
      tableName,
      columns: columns,
      orderBy: defaultOrderColumn,
    );
    return Map.fromEntries(
      maps.map((e) => MapEntry(e[primaryColumnName] as Identifier, fromMap(e))),
    );
  }

  @override
  Future<void> removeItem(Identifier id) async {
    await db
        .delete(tableName, where: '$primaryColumnName = ?', whereArgs: [id]);
  }

  @override
  Future<void> setItem(Identifier id, Item item) async {
    final map = toMap(item);
    await db.insert(
      tableName,
      map,
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> clear() async {
    await db.delete(tableName);
  }
}

class SqliteUserCache extends _SqliteCache<String, User> {
  SqliteUserCache(sqflite.Database db)
      : super(
          db,
          tableName: "users",
          primaryColumnName: "username",
          columns: [
            "_id",
            "createdAt",
            "updatedAt",
            "version",
            "firebaseId",
            "username",
            "email",
            "phoneNumber",
            "pictureURL",
            "mainBudget",
            "miscCategory",
          ],
          toMap: (u) => u.toJson()
            ..update("createdAt", (t) => u.createdAt.millisecondsSinceEpoch)
            ..update("updatedAt", (t) => u.updatedAt.millisecondsSinceEpoch),
          fromMap: (m) => User.fromJson(
            Map.from(m)
              ..update(
                  "createdAt",
                  (t) => DateTime.fromMillisecondsSinceEpoch(t as int)
                      .toIso8601String())
              ..update(
                  "updatedAt",
                  (t) => DateTime.fromMillisecondsSinceEpoch(t as int)
                      .toIso8601String()),
          ),
        );
}

class SqliteBudgetCache extends _SqliteCache<String, Budget> {
  SqliteBudgetCache(sqflite.Database db)
      : super(
          db,
          tableName: "budgets",
          primaryColumnName: "_id",
          columns: [
            "_id",
            "createdAt",
            "updatedAt",
            "version",
            "archivedAt",
            "isServerVersion",
            "name",
            "startTime",
            "endTime",
            "allocatedAmountCurrency",
            "allocatedAmountValue",
            "frequencyKind",
            "frequencyRecurringIntervalSecs",
            "categoryAllocations",
          ],
          defaultOrderColumn: "createdAt",
          toMap: (o) => o.toJson()
            ..update("createdAt", (t) => o.createdAt.millisecondsSinceEpoch)
            ..update("updatedAt", (t) => o.updatedAt.millisecondsSinceEpoch)
            ..update("isServerVersion", (t) => o.isServerVersion ? 1 : 0)
            ..update("startTime", (t) => o.startTime.millisecondsSinceEpoch)
            ..update("endTime", (t) => o.endTime.millisecondsSinceEpoch)
            ..update("archivedAt", (t) => o.archivedAt?.millisecondsSinceEpoch)
            ..update("categoryAllocations", (t) => jsonEncode(t))
            ..["allocatedAmountCurrency"] = o.allocatedAmount.currency
            ..["allocatedAmountValue"] = o.allocatedAmount.amount
            ..["frequencyKind"] = o.frequency.kind.toString()
            ..["frequencyRecurringIntervalSecs"] = o.frequency is Recurring
                ? (o.frequency as Recurring).recurringIntervalSecs
                : null
            ..remove("allocatedAmount")
            ..remove("frequency"),
          fromMap: (m) => Budget.fromJson(
            Map.from(m)
              ..update(
                  "createdAt",
                  (t) => DateTime.fromMillisecondsSinceEpoch(t as int)
                      .toIso8601String())
              ..update(
                  "updatedAt",
                  (t) => DateTime.fromMillisecondsSinceEpoch(t as int)
                      .toIso8601String())
              ..update(
                  "startTime",
                  (t) => DateTime.fromMillisecondsSinceEpoch(t as int)
                      .toIso8601String())
              ..update(
                  "endTime",
                  (t) => DateTime.fromMillisecondsSinceEpoch(t as int)
                      .toIso8601String())
              ..update(
                  "archivedAt",
                  (t) => t != null
                      ? DateTime.fromMillisecondsSinceEpoch(t as int)
                          .toIso8601String()
                      : null)
              ..update("categoryAllocations", (t) => jsonDecode(t))
              ..update("isServerVersion", (t) => m["isServerVersion"] == 1)
              ..["allocatedAmount"] = {
                "currency": m["allocatedAmountCurrency"],
                "amount": m["allocatedAmountValue"],
              }
              ..["frequency"] = {
                "kind": m["frequencyKind"],
                "recurringIntervalSecs": m["frequencyRecurringIntervalSecs"],
              },
          ),
        );
}

class SqliteCategoryCache extends _SqliteCache<String, Category> {
  SqliteCategoryCache(sqflite.Database db)
      : super(
          db,
          tableName: "categories",
          primaryColumnName: "_id",
          columns: [
            "_id",
            "createdAt",
            "updatedAt",
            "version",
            "isServerVersion",
            "archivedAt",
            "name",
            "parentId",
            "tags",
          ],
          defaultOrderColumn: "createdAt",
          toMap: (o) => o.toJson()
            ..update("createdAt", (t) => o.createdAt.millisecondsSinceEpoch)
            ..update("updatedAt", (t) => o.updatedAt.millisecondsSinceEpoch)
            ..update("archivedAt", (t) => o.archivedAt?.millisecondsSinceEpoch)
            ..update("isServerVersion", (t) => o.isServerVersion ? 1 : 0)
            ..update("tags", (t) => o.tags.join(","))
            // ..["allocatedAmountCurrency"] = o.allocatedAmount.currency
            // ..["allocatedAmountValue"] = o.allocatedAmount.amount
            ..remove("allocatedAmount")
            ..remove("categories"),
          fromMap: (m) => Category.fromJson(
            Map.from(m)
              ..update(
                  "createdAt",
                  (t) => DateTime.fromMillisecondsSinceEpoch(t as int)
                      .toIso8601String())
              ..update(
                  "updatedAt",
                  (t) => DateTime.fromMillisecondsSinceEpoch(t as int)
                      .toIso8601String())
              ..update(
                  "archivedAt",
                  (t) => t != null
                      ? DateTime.fromMillisecondsSinceEpoch(t as int)
                          .toIso8601String()
                      : null)
              ..update(
                  "tags", (t) => (t as String).isNotEmpty ? t.split(",") : [])
              ..update("isServerVersion", (t) => m["isServerVersion"] == 1)
              ..["parentCategory"] = m["parentId"] == null
                  ? null
                  : {
                      "_id": m["parentId"],
                    },
          ),
        );
}

class SqliteExpenseCache extends _SqliteCache<String, Expense> {
  SqliteExpenseCache(sqflite.Database db)
      : super(
          db,
          tableName: "expenses",
          primaryColumnName: "_id",
          columns: [
            "_id",
            "createdAt",
            "updatedAt",
            "version",
            "isServerVersion",
            "name",
            "timestamp",
            "categoryId",
            "budgetId",
            "amountCurrency",
            "amountValue",
          ],
          defaultOrderColumn: "timestamp",
          toMap: (o) => o.toJson()
            ..update("createdAt", (t) => o.createdAt.millisecondsSinceEpoch)
            ..update("updatedAt", (t) => o.updatedAt.millisecondsSinceEpoch)
            ..update("timestamp", (t) => o.timestamp.millisecondsSinceEpoch)
            ..update("isServerVersion", (t) => o.isServerVersion ? 1 : 0)
            ..["amountCurrency"] = o.amount.currency
            ..["amountValue"] = o.amount.amount
            ..remove("amount"),
          fromMap: (m) => Expense.fromJson(
            Map.from(m)
              ..update(
                  "createdAt",
                  (t) => DateTime.fromMillisecondsSinceEpoch(t as int)
                      .toIso8601String())
              ..update(
                  "updatedAt",
                  (t) => DateTime.fromMillisecondsSinceEpoch(t as int)
                      .toIso8601String())
              ..update(
                  "timestamp",
                  (t) => DateTime.fromMillisecondsSinceEpoch(t as int)
                      .toIso8601String())
              ..update("isServerVersion", (t) => m["isServerVersion"] == 1)
              ..["amount"] = {
                "currency": m["amountCurrency"],
                "amount": m["amountValue"],
              }
              ..["category"] = {
                "_id": m["categoryId"],
                "budgetId": m["budgetId"],
              },
          ),
        );
}

class SqliteIncomeCache extends _SqliteCache<String, Income> {
  SqliteIncomeCache(sqflite.Database db)
      : super(
          db,
          tableName: "incomes",
          primaryColumnName: "_id",
          columns: [
            "_id",
            "createdAt",
            "updatedAt",
            "version",
            "isServerVersion",
            "name",
            "timestamp",
            "amountCurrency",
            "amountValue",
            "frequencyKind",
            "frequencyRecurringIntervalSecs",
          ],
          defaultOrderColumn: "timestamp",
          toMap: (o) => o.toJson()
            ..update("createdAt", (t) => o.createdAt.millisecondsSinceEpoch)
            ..update("updatedAt", (t) => o.updatedAt.millisecondsSinceEpoch)
            ..update("timestamp", (t) => o.timestamp.millisecondsSinceEpoch)
            ..update("isServerVersion", (t) => o.isServerVersion ? 1 : 0)
            ..["amountCurrency"] = o.amount.currency
            ..["amountValue"] = o.amount.amount
            ..["frequencyKind"] = o.frequency.kind.toString()
            ..["frequencyRecurringIntervalSecs"] = o.frequency is Recurring
                ? (o.frequency as Recurring).recurringIntervalSecs
                : null
            ..remove("amount")
            ..remove("frequency"),
          fromMap: (m) => Income.fromJson(
            Map.from(m)
              ..update(
                  "createdAt",
                  (t) => DateTime.fromMillisecondsSinceEpoch(t as int)
                      .toIso8601String())
              ..update(
                  "updatedAt",
                  (t) => DateTime.fromMillisecondsSinceEpoch(t as int)
                      .toIso8601String())
              ..update(
                  "timestamp",
                  (t) => DateTime.fromMillisecondsSinceEpoch(t as int)
                      .toIso8601String())
              ..update("isServerVersion", (t) => m["isServerVersion"] == 1)
              ..["amount"] = {
                "currency": m["amountCurrency"],
                "amount": m["amountValue"],
              }
              ..["frequency"] = {
                "kind": m["frequencyKind"],
                "recurringIntervalSecs": m["frequencyRecurringIntervalSecs"],
              },
          ),
        );
}

class ServerVersionSqliteCache<Identifier, Item>
    extends Cache<Identifier, Item> {
  final _SqliteCache<Identifier, Item> cache;

  ServerVersionSqliteCache(this.cache) {
    cache.tableName = "$_serverVersionPrefix${cache.tableName}";
  }

  @override
  Future<void> clear() => cache.clear();

  @override
  Future<Item?> getItem(Identifier id) => cache.getItem(id);

  @override
  Future<Map<Identifier, Item>> getItems() => cache.getItems();
  @override
  Future<void> removeItem(Identifier id) => cache.removeItem(id);
  @override
  Future<void> setItem(Identifier id, Item item) => cache.setItem(id, item);
}

class _SqliteRemovedItemsCache extends RemovedItemsCache<String> {
  final _SqliteCache<String, String> actualCache;
  _SqliteRemovedItemsCache(sqflite.Database db, String tableName)
      : actualCache = _SqliteCache(
          db,
          tableName: tableName,
          primaryColumnName: "_id",
          columns: ["_id"],
          toMap: (o) => {"_id": o},
          fromMap: (m) => m["_id"],
        );

  @override
  Future<void> add(String id) async => actualCache.setItem(id, id);

  @override
  Future<void> clear() async => actualCache.clear();

  @override
  Future<List<String>> getItems() async =>
      (await actualCache.getItems()).values.toList();

  @override
  Future<bool> has(String id) async => await actualCache.getItem(id) != null;

  @override
  Future<void> remove(String id) => actualCache.removeItem(id);
}

class SqliteRemovedBudgetsCache extends _SqliteRemovedItemsCache {
  SqliteRemovedBudgetsCache(sqflite.Database db) : super(db, "removedBudgets");
}

class SqliteRemovedCategoriesCache extends _SqliteRemovedItemsCache {
  SqliteRemovedCategoriesCache(sqflite.Database db)
      : super(db, "removedCategories");
}

class SqliteRemovedExpensesCache extends _SqliteRemovedItemsCache {
  SqliteRemovedExpensesCache(sqflite.Database db)
      : super(db, "removedExpenses");
}

class SqliteRemovedIncomesCache extends _SqliteRemovedItemsCache {
  SqliteRemovedIncomesCache(sqflite.Database db) : super(db, "removedIncomes");
}
