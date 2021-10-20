import 'package:test/test.dart';

import 'package:smuni_api_client/smuni_api_client.dart';

@TestOn('vm')
void main() {
  final client = SmuniApiClient("http://localhost:3000");
  group("post /auth_token", () {
    late String token;
    late UserDenorm testUser;
    setUp(() async {
      final resp = await setupTestUser(client);
      token = resp.accessToken;
      testUser = resp.user;
    });
    tearDown(() async => await client.deleteUser(testUser.username, token));

    test("supports email signIn", () async {
      var response = await client.signInEmail(testUser.email!, "password");
      expect(response.accessToken, isNotEmpty);
      expect(response.refreshToken, isNotEmpty);
      expect(response.user.id, equals(testUser.id));
    });
    test("supports phoneNumber signIn", () async {
      var response =
          await client.signInPhone(testUser.phoneNumber!, "password");
      expect(response.accessToken, isNotEmpty);
      expect(response.refreshToken, isNotEmpty);
      expect(response.user.id, equals(testUser.id));
    });
    test("throws when password wrong", () {
      expect(
        () => client.signInPhone(testUser.phoneNumber!, "invalid"),
        throwsEndpointError(
          400,
          "CredentialsRejected",
        ),
      );
    });
    test("throws when email wrong", () {
      expect(
        () => client.signInEmail("invalid", "password"),
        throwsEndpointError(
          400,
          "CredentialsRejected",
        ),
      );
    });
    test("throws when phoneNumber wrong", () {
      expect(
        () => client.signInPhone("invalid", "password"),
        throwsEndpointError(
          400,
          "CredentialsRejected",
        ),
      );
    });
  });

// USER

  group("get /users/:username", () {
    late String token;
    late UserDenorm testUser;
    setUp(() async {
      final resp = await setupTestUser(client);
      token = resp.accessToken;
      testUser = resp.user;
    });
    tearDown(() async => await client.deleteUser(testUser.username, token));

    test("succeeds", () async {
      var response = await client.getUser(testUser.username, token);
      expect(response.id, isNotEmpty);
      expect(response.username, equals(testUser.username));
    });
    test("throws when not found", () {
      expect(
        () => client.getUser("randomrandom", token),
        throwsEndpointError(
          403,
          "AccessDenied",
        ),
      );
    });
  });

  group("post /users", () {
    final username = "crash_test_dummy";
    final firebaseId = "1234567ABCDEFGHHGFEDCBA76543";
    final password = "password";
    final email = "exist@tsixe.ed";
    final phoneNumber = "+251912344321";

    late String token;
    late UserDenorm testUser;
    setUp(() async {
      try {
        final token = (await client.signInEmail(email, password)).accessToken;
        await client.deleteUser(username, token);
        // ignore: empty_catches
      } catch (e) {}

      final resp = await setupTestUser(client);
      token = resp.accessToken;
      testUser = resp.user;
    });
    tearDown(() async {
      try {
        final token = (await client.signInEmail(email, password)).accessToken;
        await client.deleteUser(username, token);
        // ignore: empty_catches
      } catch (e) {}

      await client.deleteUser(testUser.username, token);
    });
    test("throws if email and phoneNumber missing", () {
      expect(
        () => client.createUser(CreateUserInput(
          username: username,
          password: password,
          firebaseId: firebaseId,
        )),
        throwsException,
      );
    });
    test("throws if username occupied", () {
      expect(
        () => client.createUser(CreateUserInput(
          username: testUser.username,
          password: password,
          firebaseId: firebaseId,
          email: email,
        )),
        throwsEndpointError(
          400,
          "UsernameOccupied",
        ),
      );
    });
    test("throws if email occupied", () {
      expect(
        () => client.createUser(CreateUserInput(
          username: username,
          password: password,
          firebaseId: firebaseId,
          email: testUser.email!,
        )),
        throwsEndpointError(
          400,
          "EmailOccupied",
        ),
      );
    });
    test("throws if phoneNumber occupied", () {
      expect(
        () => client.createUser(CreateUserInput(
          username: username,
          password: password,
          firebaseId: firebaseId,
          phoneNumber: testUser.phoneNumber!,
        )),
        throwsEndpointError(
          400,
          "PhoneNumberOccupied",
        ),
      );
    });

    // run the succeds test last to avoid occupied errors
    test("succeeds", () async {
      var response = await client.createUser(CreateUserInput(
        username: username,
        password: password,
        email: email,
        phoneNumber: phoneNumber,
        firebaseId: firebaseId,
      ));
      expect(response.id, isNotEmpty);
      expect(response.username, equals(username));
      expect(response.email, equals(email));
      expect(response.phoneNumber, equals(phoneNumber));
      expect(response.firebaseId, equals(firebaseId));
    });
  });

  group("patch /users/:username", () {
    final username = "crash_test_dummy";
    final pictureURL = "https://138924jhe.asdf/ui243o1";
    final password = "password";
    final email = "exist@tsixe.ed";
    final phoneNumber = "+251912344321";

    late String token;
    late UserDenorm testUser;
    setUp(() async {
      final resp = await setupTestUser(client);
      token = resp.accessToken;
      testUser = resp.user;
    });
    tearDown(() async {
      final resp =
          (await client.signInFirebaseId(testUser.firebaseId, password));
      await client.deleteUser(resp.user.username, resp.accessToken);
    });

    test("succeeds", () async {
      var response = await client.updateUser(
          testUser.username,
          token,
          UpdateUserInput(
            newUsername: username,
            email: email,
            password: password,
            phoneNumber: phoneNumber,
            pictureURL: pictureURL,
            lastSeenVersion: testUser.version,
          ));
      expect(response.username, equals(username));
      expect(response.email, equals(email));
      expect(response.phoneNumber, equals(phoneNumber));
      expect(response.pictureURL, equals(pictureURL));
    });
    test("throws when not found", () {
      expect(
        () => client.updateUser(
            "randomrandom",
            token,
            UpdateUserInput(
              email: email,
              lastSeenVersion: 0,
            )),
        throwsEndpointError(
          403,
          "AccessDenied",
        ),
      );
    });
  });

  group("delete /users/:username", () {
    late String token;
    late UserDenorm testUser;
    setUp(() async {
      final resp = await setupTestUser(client);
      token = resp.accessToken;
      testUser = resp.user;
    });
    tearDown(() async => await client.deleteUser(testUser.username, token));

    test("succeeds", () async {
      await client.deleteUser(testUser.username, token);
    });
  });

// BUDGET

  group("get /users/:username/budgets/:budgetId", () {
    late String token;
    late UserDenorm testUser;
    setUp(() async {
      final resp = await setupTestUser(client);
      token = resp.accessToken;
      testUser = resp.user;
    });
    tearDown(() async => await client.deleteUser(testUser.username, token));

    test("succeeds", () async {
      var response = await client.getBudget(
        testUser.budgets[0].id,
        testUser.username,
        token,
      );
      expect(response.id, isNotEmpty);
      expect(response.name, equals(testUser.budgets[0].name));
    });
    test("throws when not found", () {
      expect(
        () => client.getBudget(
          "614193c7f2ea51b47f5896be",
          testUser.username,
          token,
        ),
        throwsEndpointError(
          404,
          "BudgetNotFound",
        ),
      );
    });
  });

  group("post /users/:username/budgets", () {
    late String token;
    late UserDenorm testUser;
    setUp(() async {
      final resp = await setupTestUser(client);
      token = resp.accessToken;
      testUser = resp.user;
    });
    tearDown(() async => await client.deleteUser(testUser.username, token));

    final name = "Diary budget";
    final allocatedAmount = MonetaryAmount(currency: "ETB", amount: 1000 * 100);
    final frequency = OneTime();
    final startTime = DateTime.now();
    final endTime = startTime.add(Duration(days: 7));
    test("succeeds", () async {
      final categoryAllocations = {
        testUser.categories[0].id: 500 * 100,
        testUser.categories[1].id: 500 * 100,
      };

      var response = await client.createBudget(
          testUser.username,
          token,
          CreateBudgetInput(
            name: name,
            allocatedAmount: allocatedAmount,
            frequency: frequency,
            startTime: startTime,
            endTime: endTime,
            categoryAllocations: categoryAllocations,
          ));
      expect(response.id, isNotEmpty);
      expect(response.name, equals(name));
      expect(response.allocatedAmount, equals(allocatedAmount));
      expect(response.frequency, equals(frequency));
      expect(response.startTime.millisecondsSinceEpoch,
          equals(startTime.millisecondsSinceEpoch));
      expect(response.endTime.millisecondsSinceEpoch,
          equals(endTime.millisecondsSinceEpoch));
    });
    test("throws if category not found", () {
      expect(
        () => client.createBudget(
            testUser.username,
            token,
            CreateBudgetInput(
              name: name,
              allocatedAmount: allocatedAmount,
              frequency: frequency,
              startTime: startTime,
              endTime: endTime,
              categoryAllocations: {"614193c7f2ea51b47f5896be": 1000 * 100},
            )),
        throwsEndpointError(
          404,
          "CategoryNotFound",
        ),
      );
    });
  });

  group("patch /users/:username/budgets/:budgetId", () {
    late String token;
    late UserDenorm testUser;
    setUp(() async {
      final resp = await setupTestUser(client);
      token = resp.accessToken;
      testUser = resp.user;
    });
    tearDown(() async => await client.deleteUser(testUser.username, token));

    final name = "Dairy budget";
    final allocatedAmount = MonetaryAmount(currency: "ETB", amount: 1000 * 100);
    final frequency = OneTime();
    final startTime = DateTime.now();
    final endTime = startTime.add(Duration(days: 7));
    final archive = true;

    test("succeeds", () async {
      final categoryAllocations = {
        testUser.categories[0].id: 500 * 100,
        testUser.categories[1].id: 500 * 100,
      };
      var response = await client.updateBudget(
          testUser.budgets[0].id,
          testUser.username,
          token,
          UpdateBudgetInput(
            lastSeenVersion: testUser.budgets[0].version,
            name: name,
            allocatedAmount: allocatedAmount,
            frequency: frequency,
            startTime: startTime,
            endTime: endTime,
            categoryAllocations: categoryAllocations,
            archive: archive,
          ));
      expect(response.name, equals(name));
      expect(response.allocatedAmount, equals(allocatedAmount));
      expect(response.frequency, equals(frequency));
      expect(response.startTime.millisecondsSinceEpoch,
          equals(startTime.millisecondsSinceEpoch));
      expect(response.endTime.millisecondsSinceEpoch,
          equals(endTime.millisecondsSinceEpoch));
      expect(response.archivedAt, isNotNull);
    });
    test("throws when not found", () {
      expect(
        () => client.updateBudget(
          "614193c7f2ea51b47f5896be",
          testUser.username,
          token,
          UpdateBudgetInput(lastSeenVersion: 0, name: name),
        ),
        throwsEndpointError(
          404,
          "BudgetNotFound",
        ),
      );
    });
    test("throws if category not found", () {
      expect(
        () => client.updateBudget(
          testUser.budgets[0].id,
          testUser.username,
          token,
          UpdateBudgetInput(
            categoryAllocations: {"614193c7f2ea51b47f5896be": 1000 * 100},
            lastSeenVersion: testUser.budgets[0].version,
          ),
        ),
        throwsEndpointError(
          404,
          "CategoryNotFound",
        ),
      );
    });
  });

  group("delete /users/:username/budgets/:budgetId", () {
    late String token;
    late UserDenorm testUser;
    setUp(() async {
      final resp = await setupTestUser(client);
      token = resp.accessToken;
      testUser = resp.user;
    });
    tearDown(() async => await client.deleteUser(testUser.username, token));

    test("succeeds", () async {
      await client.deleteBudget(
        testUser.budgets[0].id,
        testUser.username,
        token,
      );
    });
  });

// CATEGORY

  group("get /users/:username/categories/:categoryId", () {
    late String token;
    late UserDenorm testUser;
    setUp(() async {
      final resp = await setupTestUser(client);
      token = resp.accessToken;
      testUser = resp.user;
    });
    tearDown(() async => await client.deleteUser(testUser.username, token));

    test("succeeds", () async {
      var response = await client.getCategory(
        testUser.categories[0].id,
        testUser.username,
        token,
      );
      expect(response.id, isNotEmpty);
      expect(response.name, equals(testUser.categories[0].name));
    });
    test("throws when not found", () {
      expect(
        () => client.getCategory(
          "614193c7f2ea51b47f5896be",
          testUser.username,
          token,
        ),
        throwsEndpointError(
          404,
          "CategoryNotFound",
        ),
      );
    });
  });

  group("post /users/:username/categories", () {
    late String token;
    late UserDenorm testUser;
    setUp(() async {
      final resp = await setupTestUser(client);
      token = resp.accessToken;
      testUser = resp.user;
    });
    tearDown(() async => await client.deleteUser(testUser.username, token));

    final name = "Simping";
    final tags = ["vice"];
    test("succeeds", () async {
      final parentId = testUser.categories[0].id;

      var response = await client.createCategory(
          testUser.username,
          token,
          CreateCategoryInput(
            name: name,
            tags: tags,
            parentId: parentId,
          ));
      expect(response.id, isNotEmpty);
      expect(response.name, equals(name));
      expect(response.tags, equals(tags));
      expect(response.parentId, equals(parentId));
    });
    test("throws if category not found", () {
      expect(
        () => client.createCategory(
          testUser.username,
          token,
          CreateCategoryInput(
            name: name,
            tags: tags,
            parentId: "614193c7f2ea51b47f5896be",
          ),
        ),
        throwsEndpointError(
          404,
          "CategoryNotFound",
        ),
      );
    });
  });

  group("patch /users/:username/categories/:categoryId", () {
    late String token;
    late UserDenorm testUser;
    setUp(() async {
      final resp = await setupTestUser(client);
      token = resp.accessToken;
      testUser = resp.user;
    });
    tearDown(() async => await client.deleteUser(testUser.username, token));

    final name = "Simping";
    final tags = ["vice"];
    final archive = true;

    test("succeeds", () async {
      final parentId = testUser.categories[0].id;

      var response = await client.updateCategory(
          testUser.categories[0].id,
          testUser.username,
          token,
          UpdateCategoryInput(
            lastSeenVersion: testUser.categories[0].version,
            name: name,
            tags: tags,
            parentId: parentId,
            archive: archive,
          ));
      expect(response.name, equals(name));
      expect(response.tags, equals(tags));
      expect(response.parentId, equals(parentId));
      expect(response.archivedAt, isNotNull);
    });
    test("throws when not found", () {
      expect(
        () => client.updateCategory(
          "614193c7f2ea51b47f5896be",
          testUser.username,
          token,
          UpdateCategoryInput(name: name, lastSeenVersion: 0),
        ),
        throwsEndpointError(
          404,
          "CategoryNotFound",
        ),
      );
    });
    test("throws if category not found", () {
      expect(
        () => client.updateCategory(
            testUser.categories[0].id,
            testUser.username,
            token,
            UpdateCategoryInput(
              lastSeenVersion: testUser.categories[0].version,
              parentId: "614193c7f2ea51b47f5896be",
            )),
        throwsEndpointError(
          404,
          "CategoryNotFound",
        ),
      );
    });
  });

  group("delete /users/:username/categories/:categoryId", () {
    late String token;
    late UserDenorm testUser;
    setUp(() async {
      final resp = await setupTestUser(client);
      token = resp.accessToken;
      testUser = resp.user;
    });
    tearDown(() async => await client.deleteUser(testUser.username, token));

    test("succeeds", () async {
      await client.deleteBudget(
        testUser.categories[0].id,
        testUser.username,
        token,
      );
    });
  });

// EXPENSE

  group("get /users/:username/expenses/:expenseId", () {
    late String token;
    late UserDenorm testUser;
    setUp(() async {
      final resp = await setupTestUser(client);
      token = resp.accessToken;
      testUser = resp.user;
    });
    tearDown(() async => await client.deleteUser(testUser.username, token));

    test("succeeds", () async {
      var response = await client.getExpense(
        testUser.expenses[0].id,
        testUser.username,
        token,
      );
      expect(response.id, isNotEmpty);
      expect(response.name, equals(testUser.expenses[0].name));
    });
    test("throws when not found", () {
      expect(
        () => client.getExpense(
          "614193c7f2ea51b47f5896be",
          testUser.username,
          token,
        ),
        throwsEndpointError(
          404,
          "ExpenseNotFound",
        ),
      );
    });
  });

  group("post /users/:username/expenses", () {
    late String token;
    late UserDenorm testUser;
    setUp(() async {
      final resp = await setupTestUser(client);
      token = resp.accessToken;
      testUser = resp.user;
    });
    tearDown(() async => await client.deleteUser(testUser.username, token));

    final name = "Business Hymns CD 1";
    final amount = MonetaryAmount(currency: "ETB", amount: 100 * 100);
    final timestamp = DateTime.now();

    test("succeeds", () async {
      final budgetId = testUser.budgets[0].id;
      final categoryId = testUser.categories[0].id;

      var response = await client.createExpense(
          testUser.username,
          token,
          CreateExpenseInput(
            name: name,
            amount: amount,
            budgetId: budgetId,
            categoryId: categoryId,
            timestamp: timestamp,
          ));
      expect(response.id, isNotEmpty);
      expect(response.name, equals(name));
      expect(response.amount, equals(amount));
      expect(response.budgetId, equals(budgetId));
      expect(response.categoryId, equals(categoryId));
      expect(response.timestamp.millisecondsSinceEpoch,
          equals(timestamp.millisecondsSinceEpoch));
    });
    test("throws if budget not found", () {
      final categoryId = testUser.categories[0].id;
      expect(
        () => client.createExpense(
            testUser.username,
            token,
            CreateExpenseInput(
              name: name,
              amount: amount,
              budgetId: "614193c7f2ea51b47f5896be",
              categoryId: categoryId,
              timestamp: timestamp,
            )),
        throwsEndpointError(
          404,
          "BudgetNotFound",
        ),
      );
    });
    test("throws if category not found", () {
      final budgetId = testUser.budgets[0].id;
      expect(
        () => client.createExpense(
            testUser.username,
            token,
            CreateExpenseInput(
              name: name,
              amount: amount,
              budgetId: budgetId,
              categoryId: "614193c7f2ea51b47f5896be",
              timestamp: timestamp,
            )),
        throwsEndpointError(
          404,
          "CategoryNotFound",
        ),
      );
    });
  });

  group("patch /users/:username/expenses/:expenseId", () {
    late String token;
    late UserDenorm testUser;
    setUp(() async {
      final resp = await setupTestUser(client);
      token = resp.accessToken;
      testUser = resp.user;
    });
    tearDown(() async => await client.deleteUser(testUser.username, token));

    final name = "Business Hymns CD 1";
    final amount = MonetaryAmount(currency: "ETB", amount: 100 * 100);
    final timestamp = DateTime.now().subtract(Duration(days: 1));

    test("succeeds", () async {
      var response = await client.updateExpense(
          testUser.expenses[0].id,
          testUser.username,
          token,
          UpdateExpenseInput(
            lastSeenVersion: testUser.expenses[0].version,
            name: name,
            amount: amount,
            timestamp: timestamp,
          ));
      expect(response.name, equals(name));
      expect(response.amount, equals(amount));
    });
    test("throws when not found", () {
      expect(
        () => client.updateExpense(
          "614193c7f2ea51b47f5896be",
          testUser.username,
          token,
          UpdateExpenseInput(name: name, lastSeenVersion: 0),
        ),
        throwsEndpointError(
          404,
          "ExpenseNotFound",
        ),
      );
    });
  });

  group("delete /users/:username/expenses/:expenseId", () {
    late String token;
    late UserDenorm testUser;
    setUp(() async {
      final resp = await setupTestUser(client);
      token = resp.accessToken;
      testUser = resp.user;
    });
    tearDown(() async => await client.deleteUser(testUser.username, token));

    test("succeeds", () async {
      await client.deleteExpense(
        testUser.expenses[0].id,
        testUser.username,
        token,
      );
    });
  });
}

Matcher throwsEndpointError(
  int code,
  String type,
) =>
    throwsA(
      allOf(
        isA<EndpointError>(),
        predicate<EndpointError>((err) => err.code == code, "matches code"),
        predicate<EndpointError>((err) => err.type == type, "matches type"),
      ),
    );

Future<SignInResponse> setupTestUser(SmuniApiClient client) async {
  final password = "password";
  final username = "client_test_dummy";
  final email = "hello@under.world";
  try {
    final token = (await client.signInEmail(email, password)).accessToken;
    await client.deleteUser(username, token);
    // ignore: empty_catches
  } catch (e) {}

  final user = await client.createUser(CreateUserInput(
    username: username,
    password: password,
    email: email,
    phoneNumber: "+251900001212",
    firebaseId: "1234567ABCDEFGHHGFEDCBA00000",
  ));
  final token = (await client.signInEmail(email, password)).accessToken;
  late Category category01;
  late Category category02;
  {
    category01 = await client.createCategory(
        user.username,
        token,
        CreateCategoryInput(
          name: "Medicine",
          tags: ["pharma"],
        ));
    category02 = await client.createCategory(
        user.username,
        token,
        CreateCategoryInput(
          name: "RejuvPill",
          tags: ["pharma", "health"],
        ));
  }
  late Budget budget01;
  {
    budget01 = await client.createBudget(
      user.username,
      token,
      CreateBudgetInput(
        name: "Monthly budget",
        allocatedAmount: MonetaryAmount(currency: "ETB", amount: 2000 * 100),
        frequency: Recurring(2592000),
        startTime: DateTime.parse("2021-07-31T21:00:00.000Z"),
        endTime: DateTime.parse("2021-08-31T21:00:00.000Z"),
        categoryAllocations: {
          category01.id: 1000 * 100,
          category02.id: 1000 * 100,
        },
      ),
    );
    await client.createBudget(
        user.username,
        token,
        CreateBudgetInput(
          name: "Special budget",
          startTime: DateTime.parse("2021-07-31T21:00:00.000Z"),
          endTime: DateTime.parse("2021-08-31T21:00:00.000Z"),
          allocatedAmount: MonetaryAmount(currency: "ETB", amount: 2000 * 100),
          frequency: OneTime(),
          categoryAllocations: {
            category01.id: 1000 * 100,
            category02.id: 1000 * 100,
          },
        ));
  }
  {
    await client.createExpense(
      user.username,
      token,
      CreateExpenseInput(
        name: "Pill purchase",
        categoryId: category02.id,
        budgetId: budget01.id,
        amount: MonetaryAmount(currency: "ETB", amount: 400 * 100),
        timestamp: DateTime.now(),
      ),
    );
    await client.createExpense(
      user.username,
      token,
      CreateExpenseInput(
        name: "Xanax purchase",
        categoryId: category01.id,
        budgetId: budget01.id,
        amount: MonetaryAmount(currency: "ETB", amount: 200 * 100),
        timestamp: DateTime.now(),
      ),
    );
  }
  return await client.signInEmail(email, password);
}
