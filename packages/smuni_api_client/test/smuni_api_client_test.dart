import 'package:smuni_api_client/smuni_api_client.dart';
import 'package:test/test.dart';

@TestOn('vm')
void main() {
  final testUser = (() {
    final now = DateTime.now();
    return User(
      id: "614193c7f2ea51b47f5896be",
      username: "superkind",
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      email: "don@key.ote",
      firebaseId: "ABCDEF_123456_ABCDEF_123456_",
      phoneNumber: "+251900112233",
      pictureURL: "https://imagine.co/9q6roh3cifnp",
      budgets: [
        Budget(
          id: "614193c7f2ea51b47f5896ba",
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          name: "Monthly budget",
          startTime: DateTime.parse("2021-07-31T21:00:00.000Z"),
          endTime: DateTime.parse("2021-08-31T21:00:00.000Z"),
          allocatedAmount: MonetaryAmount(currency: "ETB", amount: 7000 * 100),
          frequency: Recurring(2592000),
          categories: [
            Category(
              id: "fpoq3cum4cpu43241u34",
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              name: "Mental health",
              budgetId: "614193c7f2ea51b47f5896ba",
              parentId: null,
              allocatedAmount:
                  MonetaryAmount(currency: "ETB", amount: 1000 * 100),
              tags: [],
            ),
            Category(
              id: "mucpxo2ur3p98u32proxi34",
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              name: "Atmosphere",
              budgetId: "614193c7f2ea51b47f5896ba",
              parentId: "fpoq3cum4cpu43241u34",
              allocatedAmount:
                  MonetaryAmount(currency: "ETB", amount: 300 * 100),
              tags: [],
            ),
            Category(
              id: "614193c7f2ea51b47f5896b8",
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              name: "Medicine",
              budgetId: "614193c7f2ea51b47f5896ba",
              parentId: null,
              allocatedAmount:
                  MonetaryAmount(currency: "ETB", amount: 1000 * 100),
              tags: ["pharma"],
            ),
            Category(
              id: "614193c7f2ea51b47f5896b9",
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              name: "RejuvPill",
              budgetId: "614193c7f2ea51b47f5896ba",
              parentId: "614193c7f2ea51b47f5896b8",
              allocatedAmount:
                  MonetaryAmount(currency: "ETB", amount: 500 * 100),
              tags: [],
            ),
          ],
        ),
        Budget(
          id: "614193c7f2ea51b47f5896bb",
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          name: "Special budget",
          startTime: DateTime.parse("2021-07-31T21:00:00.000Z"),
          endTime: DateTime.parse("2021-08-31T21:00:00.000Z"),
          allocatedAmount: MonetaryAmount(currency: "ETB", amount: 1000 * 100),
          frequency: OneTime(),
          categories: [],
        ),
      ],
      expenses: [
        Expense(
          id: "614193c7f2ea51b47f5896bc",
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          name: "Pill purchase",
          categoryId: "614193c7f2ea51b47f5896b9",
          budgetId: "614193c7f2ea51b47f5896ba",
          amount: MonetaryAmount(currency: "ETB", amount: 400 * 100),
        ),
        Expense(
          id: "614193c7f2ea51b47f5896bd",
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          name: "Xanax purchase",
          categoryId: "614193c7f2ea51b47f5896b8",
          budgetId: "614193c7f2ea51b47f5896ba",
          amount: MonetaryAmount(currency: "ETB", amount: 200 * 100),
        ),
        Expense(
          id: "um3p24urpoi23u4crp23iuj4xp",
          createdAt: now.add(Duration(days: -1)),
          updatedAt: now.add(Duration(days: -1)),
          name: "Flower Blood incense",
          categoryId: "mucpxo2ur3p98u32proxi34",
          budgetId: "614193c7f2ea51b47f5896ba",
          amount: MonetaryAmount(currency: "ETB", amount: 50 * 100),
        ),
        Expense(
          id: "j2cpiojr2p3io4jrc92p34jr234r",
          createdAt: now.add(Duration(days: -40)),
          updatedAt: now.add(Duration(days: -40)),
          name: "Switchblade puchase",
          categoryId: "fpoq3cum4cpu43241u34",
          budgetId: "614193c7f2ea51b47f5896ba",
          amount: MonetaryAmount(currency: "ETB", amount: 100 * 100),
        ),
        Expense(
          id: "rcjp2i3ou4cr23oi4jrc324c23w",
          createdAt: now.add(Duration(days: -400)),
          updatedAt: now.add(Duration(days: -400)),
          name: "Private eye hire",
          categoryId: "fpoq3cum4cpu43241u34",
          budgetId: "614193c7f2ea51b47f5896ba",
          amount: MonetaryAmount(currency: "ETB", amount: 300 * 100),
        ),
      ],
    );
  })();

  final client = SmuniApiClient("http://localhost:3000");
  group("post /auth_token", () {
    test("supports email signIn", () async {
      var response = await client.signInEmail(testUser.email, "password");
      expect(response.accessToken, isNotEmpty);
      expect(response.refreshToken, isNotEmpty);
      expect(response.user.id, equals(testUser.id));
    });
    test("supports phoneNumber signIn", () async {
      var response = await client.signInPhone(testUser.phoneNumber, "password");
      expect(response.accessToken, isNotEmpty);
      expect(response.refreshToken, isNotEmpty);
      expect(response.user.id, equals(testUser.id));
    });
    test("throws when password wrong", () {
      expect(
        () => client.signInPhone(testUser.phoneNumber, "invalid"),
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

  group("get /users/:username", () {
    late String token;
    setUp(() async {
      token =
          (await client.signInEmail(testUser.email, "password")).accessToken;
    });
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
    final firebaseId = "1234567ABCDEFGHHGFEDCBA7654321";
    final password = "password";
    final email = "exist@tsixe.ed";
    final phoneNumber = "+251912344321";
    test("succeeds", () async {
      var response = await client.createUser(
          username: username,
          password: password,
          email: email,
          phoneNumber: phoneNumber,
          firebaseId: firebaseId);
      expect(response.id, isNotEmpty);
      expect(response.username, equals(username));
      expect(response.email, equals(email));
      expect(response.phoneNumber, equals(phoneNumber));
      expect(response.firebaseId, equals(firebaseId));
    });
    test("throws if email and phoneNumber missing", () {
      expect(
        () => client.createUser(
            username: username, password: password, firebaseId: firebaseId),
        throwsException,
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
