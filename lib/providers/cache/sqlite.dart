// TODO: optimize me

import 'dart:async';
import 'dart:convert';

import 'package:smuni/models/models.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'cache.dart';

Future<void> migrateV1(sqflite.Transaction txn) async {
  await txn.execute('''
create table users ( 
  _id text primary key,
  firebaseId text unique not null,
  username text unique  not null,
  email text unique,
  phoneNumber text unique,
  pictureURL text unique,
  mainBudget text unique,
  version integer not null,
  createdAt integer not null,
  updatedAt integer not null)
''');

  await txn.execute('''
create table budgets ( 
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
  createdAt integer not null,
  updatedAt integer not null)
''');

  await txn.execute('''
create table categories ( 
  _id text primary key,
  name text not null,
  parentId text,
  tags text not null,
  archivedAt integer,
  version integer not null,
  createdAt integer not null,
  updatedAt integer not null)
''');

  await txn.execute('''
create table expenses ( 
  _id text primary key,
  name text not null,
  timestamp integer not null,
  amountCurrency text not null,
  amountValue integer not null,
  categoryId text not null,
  budgetId text not null,
  version integer not null,
  createdAt integer not null,
  updatedAt integer not null)
''');

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
      return (maps.first as Map<String, String>)["value"];
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
}

class AuthTokenCache {
  final _StuffCache _stuffCache;

  AuthTokenCache(sqflite.Database db) : _stuffCache = _StuffCache(db);

  Future<String?> getAccessToken() => _stuffCache.getStuff("accessToken");
  Future<void> setAccessToken(String token) =>
      _stuffCache.setStuff("accessToken", token);

  Future<String?> getRefreshToken() => _stuffCache.getStuff("refreshToken");
  Future<void> setRefreshToken(String token) =>
      _stuffCache.setStuff("refreshToken", token);

  Future<String?> getUsername() => _stuffCache.getStuff("loggedInUsername");
  Future<void> setUsername(String token) =>
      _stuffCache.setStuff("loggedInUsername", token);
}

abstract class SqliteCache<Identifier, Item> extends Cache<Identifier, Item> {
  final sqflite.Database db;
  final String tableName;
  final String primaryColumnName;
  final List<String> columns;
  final Map<String, dynamic> Function(Item) toMap;
  final Item Function(Map<String, dynamic>) fromMap;

  SqliteCache(
    this.db, {
    required this.tableName,
    required this.primaryColumnName,
    required this.columns,
    required this.toMap,
    required this.fromMap,
  });

  @override
  Future<Item?> getItem(
    Identifier id,
  ) async {
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

class SqliteUserCache extends SqliteCache<String, User> {
  SqliteUserCache(sqflite.Database db)
      : super(
          db,
          tableName: "users",
          primaryColumnName: "_id",
          columns: [
            "_id",
            "createdAt",
            "updatedAt",
            "firebaseId",
            "username",
            "email",
            "phoneNumber",
            "pictureURL",
            "mainBudget",
            "version",
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

class SqliteBudgetCache extends SqliteCache<String, Budget> {
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
            "name",
            "startTime",
            "endTime",
            "allocatedAmountCurrency",
            "allocatedAmountValue",
            "frequencyKind",
            "frequencyRecurringIntervalSecs",
            "categoryAllocations",
          ],
          toMap: (o) => o.toJson()
            ..update("createdAt", (t) => o.createdAt.millisecondsSinceEpoch)
            ..update("updatedAt", (t) => o.updatedAt.millisecondsSinceEpoch)
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

class SqliteCategoryCache extends SqliteCache<String, Category> {
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
            "archivedAt",
            "name",
            "parentId",
            "tags",
          ],
          toMap: (o) => o.toJson()
            ..update("createdAt", (t) => o.createdAt.millisecondsSinceEpoch)
            ..update("updatedAt", (t) => o.updatedAt.millisecondsSinceEpoch)
            ..update("archivedAt", (t) => o.archivedAt?.millisecondsSinceEpoch)
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
              ..["parentCategory"] = m["parentId"] == null
                  ? null
                  : {
                      "_id": m["parentId"],
                    },
          ),
        );
}

class SqliteExpenseCache extends SqliteCache<String, Expense> {
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
            "name",
            "timestamp",
            "categoryId",
            "budgetId",
            "amountCurrency",
            "amountValue",
          ],
          toMap: (o) => o.toJson()
            ..update("createdAt", (t) => o.createdAt.millisecondsSinceEpoch)
            ..update("updatedAt", (t) => o.updatedAt.millisecondsSinceEpoch)
            ..update("timestamp", (t) => o.timestamp.millisecondsSinceEpoch)
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
