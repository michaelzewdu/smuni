// TODO: optimize me

export 'hash_map.dart';

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:smuni/models/models.dart';
import 'package:smuni/utilities.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'repositories.dart';

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
  version integer not null,
  createdAt integer not null,
  updatedAt integer not null)
''');

  await txn.execute('''
create table expenses ( 
  _id text primary key,
  name text not null,
  amountCurrency text not null,
  amountValue integer not null,
  categoryId text not null,
  budgetId text not null,
  version integer not null,
  createdAt integer not null,
  updatedAt integer not null)
''');
}

abstract class SqliteRepository<Identfier, Item>
    extends Repository<Identfier, Item> {
  final sqflite.Database db;
  final String tableName;
  final String primaryColumnName;
  final List<String> columns;
  final Map<String, dynamic> Function(Item) toMap;
  final Item Function(Map<String, dynamic>) fromMap;

  SqliteRepository(
    this.db, {
    required this.tableName,
    required this.primaryColumnName,
    required this.columns,
    required this.toMap,
    required this.fromMap,
  });

  @override
  Future<Item?> getItem(
    Identfier id,
  ) async {
    List<Map<String, Object?>> maps = await db.query(tableName,
        columns: columns, where: '$primaryColumnName = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<Map<Identfier, Item>> getItems() async {
    List<Map<String, Object?>> maps = await db.query(
      tableName,
      columns: columns,
    );
    return HashMap.fromIterable(
      maps.map((e) => MapEntry(e[primaryColumnName], fromMap(e))),
    );
  }

  @override
  Future<void> removeItem(Identfier id) async {
    await db
        .delete(tableName, where: '$primaryColumnName = ?', whereArgs: [id]);
  }

  @override
  Future<void> setItem(Identfier id, Item item) async {
    final map = toMap(item);
    await db.insert(
      tableName,
      map,
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
    _changedItemsController.add([id]);
  }

  final StreamController<List<Identfier>> _changedItemsController =
      StreamController.broadcast();

  @override
  Stream<List<Identfier>> get changedItems => _changedItemsController.stream;
}

class SqliteUserRepository extends SqliteRepository<String, User> {
  SqliteUserRepository(sqflite.Database db)
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
            HashMap.from(m)
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

class SqliteBudgetRepository extends SqliteRepository<String, Budget> {
  SqliteBudgetRepository(sqflite.Database db)
      : super(
          db,
          tableName: "budgets",
          primaryColumnName: "_id",
          columns: [
            "_id",
            "createdAt",
            "updatedAt",
            "version",
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
            HashMap.from(m)
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

class SqliteCategoryRepository extends SqliteRepository<String, Category> {
  SqliteCategoryRepository(sqflite.Database db)
      : super(
          db,
          tableName: "categories",
          primaryColumnName: "_id",
          columns: [
            "_id",
            "createdAt",
            "updatedAt",
            "version",
            "name",
            "parentId",
            "tags",
          ],
          toMap: (o) => o.toJson()
            ..update("createdAt", (t) => o.createdAt.millisecondsSinceEpoch)
            ..update("updatedAt", (t) => o.updatedAt.millisecondsSinceEpoch)
            ..update("tags", (t) => o.tags.join(","))
            // ..["allocatedAmountCurrency"] = o.allocatedAmount.currency
            // ..["allocatedAmountValue"] = o.allocatedAmount.amount
            ..remove("allocatedAmount")
            ..remove("categories"),
          fromMap: (m) => Category.fromJson(
            HashMap.from(m)
              ..update(
                  "createdAt",
                  (t) => DateTime.fromMillisecondsSinceEpoch(t as int)
                      .toIso8601String())
              ..update(
                  "updatedAt",
                  (t) => DateTime.fromMillisecondsSinceEpoch(t as int)
                      .toIso8601String())
              ..update("tags", (t) => (t as String).split(","))
              ..["parentCategory"] = m["parentId"] == null
                  ? null
                  : {
                      "_id": m["parentId"],
                    },
          ),
        );

  Future<Map<String, TreeNode<String>>>? _ancestryGraph;
  Future<Map<String, TreeNode<String>>> get ancestryGraph {
    _ancestryGraph ??= _calcAncestryTree();
    return _ancestryGraph!;
  }

  @override
  Future<void> setItem(String id, Category item) async {
    await super.setItem(id, item);
    _ancestryGraph = null;
  }

  // FIXME: fix this func
  Future<Map<String, TreeNode<String>>> _calcAncestryTree() async {
    Map<String, TreeNode<String>> nodes = HashMap();
    final items = await getItems();

    TreeNode<String> getTreeNode(Category category) {
      var node = nodes[category.id];
      if (node == null) {
        TreeNode<String>? parentNode;
        if (category.parentId != null) {
          final parent = items[category.parentId];
          if (parent == null) {
            throw Exception("parent not found at id: $category.parentId");
          }
          parentNode = getTreeNode(parent);
          parentNode.children.add(category.id);
        }
        node = TreeNode(category.id, children: [], parent: parentNode);
        nodes[category.id] = node;
      }
      return node;
    }

    for (final category in items.values) {
      if (!nodes.containsKey(category.id)) {
        getTreeNode(category);
      }
    }
    return nodes;
  }

  /// The returned list includes the given id.
  /// Returns null if no category found under id.
  Future<List<String>?> getCategoryDescendantsTree(String forId) async {
    final graph = await ancestryGraph;
    final rootNode = graph[forId];
    if (rootNode == null) return null;

    List<String> descendants = [forId];
    void appendChildren(TreeNode<String> node) {
      descendants.addAll(node.children);
      for (final child in node.children) {
        final childNode = graph[child];
        if (childNode == null) {
          throw Exception("childNode not found in ancestryGraph at id: $child");
        }
        appendChildren(childNode);
      }
    }

    appendChildren(rootNode);

    return descendants;
  }
}

class SqliteExpenseRepository extends SqliteRepository<String, Expense> {
  SqliteExpenseRepository(sqflite.Database db)
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
            "categoryId",
            "budgetId",
            "amountCurrency",
            "amountValue",
          ],
          toMap: (o) => o.toJson()
            ..update("createdAt", (t) => o.createdAt.millisecondsSinceEpoch)
            ..update("updatedAt", (t) => o.updatedAt.millisecondsSinceEpoch)
            ..["amountCurrency"] = o.amount.currency
            ..["amountValue"] = o.amount.amount
            ..remove("amount"),
          fromMap: (m) => Expense.fromJson(
            HashMap.from(m)
              ..update(
                  "createdAt",
                  (t) => DateTime.fromMillisecondsSinceEpoch(t as int)
                      .toIso8601String())
              ..update(
                  "updatedAt",
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

  Future<Map<DateRange, DateRangeFilter>> getDateRangeFilters(
      {Set<String>? ofBudgets, Set<String>? ofCategories}) async {
    final items = await getItems();
    return generateDateRangesFilters(
      items.values
          .where(ofBudgets != null && ofCategories != null
              ? (e) =>
                  ofBudgets.contains(e.budgetId) &&
                  ofCategories.contains(e.categoryId)
              : ofBudgets != null
                  ? (e) => ofBudgets.contains(e.budgetId)
                  : ofCategories != null
                      ? (e) => ofCategories.contains(e.categoryId)
                      : (e) => true)
          .map((e) => e.createdAt),
    );
  }

  Future<Iterable<Expense>> getItemsInRange(DateRange range,
      {Set<String>? ofBudgets, Set<String>? ofCategories}) async {
    final items = await getItems();
    return items.values.where(
      ofBudgets != null && ofCategories != null
          ? (e) =>
              range.containsTimestamp(e.createdAt) &&
              ofBudgets.contains(e.budgetId) &&
              ofCategories.contains(e.categoryId)
          : ofBudgets != null
              ? (e) =>
                  range.containsTimestamp(e.createdAt) &&
                  ofBudgets.contains(e.budgetId)
              : ofCategories != null
                  ? (e) =>
                      range.containsTimestamp(e.createdAt) &&
                      ofCategories.contains(e.categoryId)
                  : (e) => range.containsTimestamp(e.createdAt),
    );
  }
}
