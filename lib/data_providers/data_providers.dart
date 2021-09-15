import 'dart:collection';

import 'package:smuni/models/models.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

abstract class DataProvider<Identfier, Item> {
  Future<Item?> getItem(Identfier id);
  Future<Iterable<Item>> getItems();
  Future<void> setItem(Identfier id, Item item);
  Future<void> removeItem(Identfier id);
}

class HashMapProvider<Identfier, Item> extends DataProvider<Identfier, Item> {
  HashMap<Identfier, Item> _items = new HashMap();

  @override
  Future<Item?> getItem(Identfier id) async {
    return _items[id];
  }

  @override
  Future<void> setItem(Identfier id, Item item) async {
    _items[id] = item;
  }

  @override
  Future<void> removeItem(Identfier id) async {
    _items.remove(id);
  }

  @override
  Future<Iterable<Item>> getItems() async {
    return _items.values;
  }
}

class UserProvider extends HashMapProvider<String, User> {}

class BudgetProvider extends HashMapProvider<String, Budget> {}

class CategoryProvider extends HashMapProvider<String, Category> {}

class ExpenseProvider extends HashMapProvider<String, Expense> {}

abstract class SqliteProvider<Identfier, Item>
    extends DataProvider<Identfier, Item> {
  final sqflite.Database db;
  final String tableName;
  final String primaryColumnName;
  final List<String> columns;
  final Map<String, dynamic> Function(Item) toMap;
  final Item Function(Map<String, dynamic>) fromMap;

  SqliteProvider(
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
    List<Map<String, Object?>> maps = await db.query(primaryColumnName,
        columns: columns, where: '$primaryColumnName = ?', whereArgs: [id]);
    if (maps.length > 0) {
      return fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<Iterable<Item>> getItems() async {
    List<Map<String, Object?>> maps = await db.query(
      primaryColumnName,
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
  }
}

/*class SqliteUserProvider extends SqliteProvider<String, User> {
  SqliteUserProvider(sqflite.Database db)
      : super(
          db,
          tableName: "users",
          primaryColumnName: "id",
          columns: [
            "id",
            "createdAt",
            "updatedAt",
          ],
          fromMap: (m) => User.fromJson(m),
          toMap: (u) => u.toJSON(),
        );

  @override
  Future<void> migrate() async {
    await db.execute('''
create table users ( 
  id text primary key,
  firebaseId text unique not null,
  username text unique  not null,
  email text unique,
  phoneNumber text unique,
  pictureURL text unique,
  createdAt text not null,
  updatedAt text not null,)
''');
  }
}
*/