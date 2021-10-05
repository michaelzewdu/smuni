import 'dart:async';
import 'dart:collection';

import 'package:smuni/models/models.dart';
import 'package:smuni/utilities.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

abstract class Repository<Identfier, Item> {
  Future<Item?> getItem(Identfier id);
  Future<Iterable<Item>> getItems();
  Future<void> setItem(Identfier id, Item item);
  Future<void> removeItem(Identfier id);
  Stream<List<Identfier>> get changedItems;
}

class HashMapRepository<Identfier, Item> extends Repository<Identfier, Item> {
  HashMap<Identfier, Item> _items = new HashMap();

  @override
  Future<Item?> getItem(Identfier id) async {
    return _items[id];
  }

  @override
  Future<void> setItem(Identfier id, Item item) async {
    _items[id] = item;
    this._changedItemsController.add([id]);
  }

  @override
  Future<void> removeItem(Identfier id) async {
    _items.remove(id);
    this._changedItemsController.add([id]);
  }

  @override
  Future<Iterable<Item>> getItems() async {
    return _items.values;
  }

  StreamController<List<Identfier>> _changedItemsController =
      StreamController.broadcast();

  @override
  Stream<List<Identfier>> get changedItems => _changedItemsController.stream;
}

class UserRepository extends HashMapRepository<String, User> {}

class BudgetRepository extends HashMapRepository<String, Budget> {}

class TreeNode<T> {
  final TreeNode<T>? parent;
  final T item;
  final List<T> children;

  TreeNode(this.item, {required this.children, this.parent});
}

class CategoryRepository extends HashMapRepository<String, Category> {
  Future<Map<String, TreeNode<String>>>? _ancestryGraph;
  Future<Map<String, TreeNode<String>>> get ancestryGraph {
    if (_ancestryGraph == null) {
      _ancestryGraph = Future.value(_calcAncestryTree());
    }
    return _ancestryGraph!;
  }

  @override
  Future<void> setItem(String id, Category item) async {
    await super.setItem(id, item);
    _ancestryGraph = null;
  }

  // FIXME: fix this func
  Map<String, TreeNode<String>> _calcAncestryTree() {
    Map<String, TreeNode<String>> nodes = HashMap();

    TreeNode<String> getTreeNode(Category category) {
      var node = nodes[category.id];
      if (node == null) {
        TreeNode<String>? parentNode;
        if (category.parentId != null) {
          final parent = this._items[category.parentId];
          if (parent == null)
            throw Exception("parent not found at id: $category.parentId");
          parentNode = getTreeNode(parent);
          parentNode.children.add(category.id);
        }
        node = TreeNode(category.id, children: [], parent: parentNode);
        nodes[category.id] = node;
      }
      return node;
    }

    for (final category in this._items.values) {
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
        if (childNode == null)
          throw Exception("childNode not found in ancestryGraph at id: $child");
        appendChildren(childNode);
      }
    }

    appendChildren(rootNode);

    return descendants;
  }
}

class ExpenseRepository extends HashMapRepository<String, Expense> {
  /*  Future<Map<DateRange, DateRangeFilter>>? _filtersFuture;
  Future<Map<DateRange, DateRangeFilter>> get dateRangeFilters {
    if (_filtersFuture == null) {
      _filtersFuture = new Future.value(
        generateDateRangesFilters(this._items.values.map((e) => e.createdAt)),
      );
    }
    return _filtersFuture!;
  } */

  Future<Map<DateRange, DateRangeFilter>> getDateRangeFilters(
      {Set<String>? ofBudgets, Set<String>? ofCategories}) async {
    return generateDateRangesFilters(this
        ._items
        .values
        .where(ofBudgets != null && ofCategories != null
            ? (e) =>
                ofBudgets.contains(e.budgetId) &&
                ofCategories.contains(e.categoryId)
            : ofBudgets != null
                ? (e) => ofBudgets.contains(e.budgetId)
                : ofCategories != null
                    ? (e) => ofCategories.contains(e.categoryId)
                    : (e) => true)
        .map((e) => e.createdAt));
  }

  Future<Iterable<Expense>> getItemsInRange(DateRange range,
      {Set<String>? ofBudgets, Set<String>? ofCategories}) async {
    return this._items.values.where(
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

  Future<void> migrate();

  @override
  Future<Item?> getItem(
    Identfier id,
  ) async {
    List<Map<String, Object?>> maps = await db.query(tableName,
        columns: columns, where: '$primaryColumnName = ?', whereArgs: [id]);
    if (maps.length > 0) {
      return fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<Iterable<Item>> getItems() async {
    List<Map<String, Object?>> maps = await db.query(
      tableName,
      columns: columns,
    );
    return maps.map((e) => fromMap(e));
  }

  @override
  Future<void> removeItem(Identfier id) async {
    await db
        .delete(tableName, where: '$primaryColumnName = ?', whereArgs: [id]);
  }

  @override
  Future<void> setItem(Identfier id, Item item) async {
    await db.insert(
      tableName,
      toMap(item),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
    this._changedItemsController.add([id]);
  }

  StreamController<List<Identfier>> _changedItemsController =
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
          ],
          toMap: (u) => u.toJSON()
            ..update("createdAt", (t) => u.updatedAt.millisecondsSinceEpoch)
            ..update("updatedAt", (t) => u.updatedAt.millisecondsSinceEpoch)
            ..remove("budgets")
            ..remove("expenses"),
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

  @override
  Future<void> migrate() async {
    await db.execute('''
create table users ( 
  _id text primary key,
  firebaseId text unique not null,
  username text unique  not null,
  email text unique,
  phoneNumber text unique,
  pictureURL text unique,
  createdAt integer not null,
  updatedAt integer not null)
''');
  }
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
            "name",
            "startTime",
            "endTime",
            "allocatedAmountCurrency",
            "allocatedAmountValue",
            "frequencyKind",
            "frequencyRecurringIntervalSecs",
          ],
          toMap: (o) => o.toJSON()
            ..update("createdAt", (t) => o.updatedAt.millisecondsSinceEpoch)
            ..update("updatedAt", (t) => o.updatedAt.millisecondsSinceEpoch)
            ..update("startTime", (t) => o.updatedAt.millisecondsSinceEpoch)
            ..update("endTime", (t) => o.updatedAt.millisecondsSinceEpoch)
            ..["allocatedAmountCurrency"] = o.allocatedAmount.currency
            ..["allocatedAmountValue"] = o.allocatedAmount.amount
            ..["frequencyKind"] = o.frequency.kind.toString()
            ..["frequencyRecurringIntervalSecs"] = o.frequency is Recurring
                ? (o.frequency as Recurring).recurringIntervalSecs
                : null
            ..remove("allocatedAmount")
            ..remove("frequency")
            ..remove("categories"),
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

  @override
  Future<void> migrate() async {
    await db.execute('''
create table budgets ( 
  _id text primary key,
  name text not null,
  startTime integer not null,
  endTime integer not null,
  allocatedAmountCurrency text not null,
  allocatedAmountValue integer not null,
  frequencyKind text not null,
  frequencyRecurringIntervalSecs integer,
  createdAt integer not null,
  updatedAt integer not null)
''');
    await db.execute('''
create table budgetCategories ( 
  budgetId text primary key,
  categoryId text primary key,
  allocatedAmountCurrency text not null,
  allocatedAmountValue integer not null,
  createdAt integer not null,
  updatedAt integer not null)
''');
  }

  @override
  Future<Budget?> getItem(
    String id,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<Iterable<Budget>> getItems() async {
    throw UnimplementedError();
  }

  @override
  Future<void> removeItem(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<void> setItem(String id, Budget item) async {
    throw UnimplementedError();
  }
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
            "name",
            "parentId",
            "tags",
          ],
          toMap: (o) => o.toJSON()
            ..update("createdAt", (t) => o.updatedAt.millisecondsSinceEpoch)
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
              ..["allocatedAmount"] = {
                "currency": m["allocatedAmountCurrency"],
                "amount": m["allocatedAmountValue"],
              }
              ..["parentCategory"] = m["parentId"] == null
                  ? null
                  : {
                      "_id": m["parentId"],
                    },
          ),
        );

  @override
  Future<void> migrate() async {
    await db.execute('''
create table categories ( 
  _id text primary key,
  name text not null,
  parentId text,
  tags text not null,
  createdAt integer not null,
  updatedAt integer not null)
''');
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
            "name",
            "categoryId",
            "budgetId",
            "amountCurrency",
            "amountValue",
          ],
          toMap: (o) => o.toJSON()
            ..update("createdAt", (t) => o.updatedAt.millisecondsSinceEpoch)
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

  @override
  Future<void> migrate() async {
    await db.execute('''
create table expenses ( 
  _id text primary key,
  name text not null,
  amountCurrency text not null,
  amountValue integer not null,
  categoryId text not null,
  budgetId text not null,
  createdAt integer not null,
  updatedAt integer not null)
''');
  }

  Map<String, DateRangeFilter> generateDateRangesFilters() {
    // TODO:
    throw UnimplementedError();
  }
}
