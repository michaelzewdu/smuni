import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smuni/providers/cache/cache.dart';
import 'package:smuni/models/models.dart';

void main() {
  // Init ffi loader if needed.

  final user = UserDenorm(
    id: "cny45347yncx093n24579xm",
    username: "deathconsciousness",
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    email: "shit.flick@lick.shit",
    firebaseId: "holyfukinshit40000",
    phoneNumber: "31415",
    pictureURL: "gemini://bad.bot",
    budgets: [
      Budget(
        id: "wnd9pucgyfwp8943yp",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        name: "Publishing",
        startTime: DateTime.parse("2021-07-31T21:00:00.000Z"),
        endTime: DateTime.parse("2021-08-31T21:00:00.000Z"),
        allocatedAmount: MonetaryAmount(currency: "ETB", amount: 700000),
        frequency: Recurring(2592000),
        categoryAllocations: {
          "13m409yh29m": 100000,
        },
      ),
    ],
    categories: [
      Category(
        id: "13m409yh29m",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        name: "Printing",
        parentId: null,
        tags: ["paper"],
      ),
    ],
    expenses: [
      Expense(
        id: "adpsfoydfuspfsduao",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        name: "The Death and Lifes of Mort",
        categoryId: "13m409yh29m",
        budgetId: "wnd9pucgyfwp8943yp",
        amount: MonetaryAmount(currency: "ETB", amount: 40000),
      ),
    ],
  );

  setUpAll(() {
    sqfliteFfiInit();
    sqflite.databaseFactory = databaseFactoryFfi;
  });
  late Database db;
  setUp(() async {
    db = await sqflite.openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) => db.transaction((txn) => migrateV1(txn)),
    );
  });
  tearDown(() => db.close());

  test("user", () async {
    final repo = SqliteUserCache(db);
    final item = User.from(user);
    await repo.setItem(item.id, item);
    final out = (await repo.getItem(user.id))!;
    expect(item.id, equals(out.id));
    expect(item.createdAt.millisecondsSinceEpoch,
        equals(out.createdAt.millisecondsSinceEpoch));
    expect(item.updatedAt.millisecondsSinceEpoch,
        equals(out.updatedAt.millisecondsSinceEpoch));
    expect(item.version, equals(out.version));
    expect(item.username, equals(out.username));
    expect(item.email, equals(out.email));
    expect(item.phoneNumber, equals(out.phoneNumber));
    expect(item.firebaseId, equals(out.firebaseId));
    expect(item.pictureURL, equals(out.pictureURL));
    expect(item.mainBudget, equals(out.mainBudget));
  });
  test("budget", () async {
    final repo = SqliteBudgetCache(db);
    final item = user.budgets[0];
    await repo.setItem(item.id, item);
    final out = (await repo.getItem(item.id))!;
    expect(item.id, equals(out.id));
    expect(item.createdAt.millisecondsSinceEpoch,
        equals(out.createdAt.millisecondsSinceEpoch));
    expect(item.updatedAt.millisecondsSinceEpoch,
        equals(out.updatedAt.millisecondsSinceEpoch));
    expect(item.version, equals(out.version));
    expect(item.name, equals(out.name));
    expect(item.frequency, equals(out.frequency));
    expect(item.allocatedAmount, equals(out.allocatedAmount));
    expect(item.categoryAllocations, equals(out.categoryAllocations));
    expect(item.startTime.millisecondsSinceEpoch,
        equals(out.startTime.millisecondsSinceEpoch));
    expect(item.endTime.millisecondsSinceEpoch,
        equals(out.endTime.millisecondsSinceEpoch));
  });
  test("category", () async {
    final db = await sqflite.openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) => db.transaction((txn) => migrateV1(txn)),
    );
    final repo = SqliteCategoryCache(db);
    final item = user.categories[0];
    await repo.setItem(item.id, item);
    final out = (await repo.getItem(item.id))!;
    expect(item.id, equals(out.id));
    expect(item.createdAt.millisecondsSinceEpoch,
        equals(out.createdAt.millisecondsSinceEpoch));
    expect(item.updatedAt.millisecondsSinceEpoch,
        equals(out.updatedAt.millisecondsSinceEpoch));
    expect(item.version, equals(out.version));
    expect(item.name, equals(out.name));
    expect(item.tags, equals(out.tags));
    expect(item.parentId, equals(out.parentId));
  });
  test("expense", () async {
    final db = await sqflite.openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) => db.transaction((txn) => migrateV1(txn)),
    );
    final repo = SqliteExpenseCache(db);
    final item = user.expenses[0];
    await repo.setItem(item.id, item);
    final out = (await repo.getItem(item.id))!;
    expect(item.id, equals(out.id));
    expect(item.createdAt.millisecondsSinceEpoch,
        equals(out.createdAt.millisecondsSinceEpoch));
    expect(item.updatedAt.millisecondsSinceEpoch,
        equals(out.updatedAt.millisecondsSinceEpoch));
    expect(item.version, equals(out.version));
    expect(item.name, equals(out.name));
    expect(item.amount, equals(out.amount));
    expect(item.budgetId, equals(out.budgetId));
    expect(item.categoryId, equals(out.categoryId));
  });
}
