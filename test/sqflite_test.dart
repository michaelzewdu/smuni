import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/models/models.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'package:sqflite_common/sqlite_api.dart';
//import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // Init ffi loader if needed.
  //TODO: Fix this Yoph
  //sqfliteFfiInit();
  //sqflite.databaseFactory = databaseFactoryFfi;
  var user = User(
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
        categories: [
          Category(
            id: "13m409yh29m",
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            name: "Printing",
            parentId: null,
            budgetId: "wnd9pucgyfwp8943yp",
            allocatedAmount: MonetaryAmount(currency: "ETB", amount: 100000),
            tags: ["paper"],
          ),
        ],
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
  test("user", () async {
    var db = await sqflite.openDatabase(inMemoryDatabasePath);
    var repo = SqliteUserRepository(db);
    await repo.migrate();
    await repo.setItem(user.id, user);
    var out = await repo.getItem(user.id);
    print(out?.toJSON());
  });
  test("budget", () async {
    var db = await sqflite.openDatabase(inMemoryDatabasePath);
    var repo = SqliteBudgetRepository(db);
    await repo.migrate();
    var item = user.budgets[0];
    await repo.setItem(user.id, item);
    var out = await repo.getItem(item.id);
    print(out?.toJSON());
  });
  test("category", () async {
    var db = await sqflite.openDatabase(inMemoryDatabasePath);
    var repo = SqliteCategoryRepository(db);
    await repo.migrate();
    var item = user.budgets[0].categories[0];
    await repo.setItem(user.id, item);
    var out = await repo.getItem(item.id);
    print(out?.toJSON());
  });
  test("expense", () async {
    var db = await sqflite.openDatabase(inMemoryDatabasePath);
    var repo = SqliteExpenseRepository(db);
    await repo.migrate();
    var item = user.expenses[0];
    await repo.setItem(user.id, item);
    var out = await repo.getItem(item.id);
    print(out?.toJSON());
  });
}
