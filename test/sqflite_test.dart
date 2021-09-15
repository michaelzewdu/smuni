import 'package:smuni/repositories/repositories.dart';
import 'package:smuni/models/models.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'package:flutter_test/flutter_test.dart';

void main() {
  var user = User(
    id: "cny45347yncx093n24579xm",
    username: "deathconsciousness",
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    email: "shit.flick@lick.shit",
    firebaseId: "holyfukinshit40000",
    phoneNumber: "31415",
    pictureURL: "gemini://bad.bot",
    budgets: [],
    expenses: [],
  );
  test("sqflite works", () async {
    var db = await sqflite.openDatabase("test.db");
    var provider = SqliteUserRepository(db);
    await provider.setItem(user.id, user);
    var out = await provider.getItem(user.id);
    print(out?.toJSON());
  });
}
