import 'dart:convert';
import 'dart:io' as io;

import 'package:http/http.dart' as http;

import './models.dart';

class SmuniApiClient {
  final String _baseUrl;
  late http.Client client;
  late JsonCodec _json;

  SmuniApiClient(this._baseUrl, {http.Client? client}) {
    _json = JsonCodec();
    if (client == null) {
      this.client = http.Client();
    }
  }

  Future<SignInResponse> _signIn(
    String identifierType,
    String identifier,
    String password,
  ) async {
    final response = await makeApiCall(
      "post",
      "/auth_token",
      jsonBody: {identifierType: identifier, "password": password},
    );
    return SignInResponse.fromJson(_json.decode(response.body));
  }

  Future<SignInResponse> signInEmail(
    String email,
    String password,
  ) =>
      _signIn("email", email, password);

  Future<SignInResponse> signInPhone(
    String phoneNumber,
    String password,
  ) =>
      _signIn("phoneNumber", phoneNumber, password);

  Future<SignInResponse> signInFirebaseId(
    String firebaseId,
    String password,
  ) =>
      _signIn("firebaseId", firebaseId, password);

  Future<UserDenorm> getUser(
    String username,
    String accessToken,
  ) async {
    final response =
        await makeApiCall("get", "/users/$username", authToken: accessToken);
    return UserDenorm.fromJson(_json.decode(response.body));
  }

  Future<UserDenorm> createUser(CreateUserInput input) async {
    if (input.email == null && input.phoneNumber == null) {
      throw Exception("email or phoneNumber are required");
    }
    final response = await makeApiCall(
      "post",
      "/users",
      jsonBody: input.toJson(),
    );
    return UserDenorm.fromJson(_json.decode(response.body));
  }

  Future<UserDenorm> updateUser(
    String username,
    String accessToken,
    UpdateUserInput input,
  ) async {
    if (input.isEmpty) throw UpdateEmptyException();
    final response = await makeApiCall(
      "patch",
      "/users/$username",
      authToken: accessToken,
      jsonBody: input.toJson(),
    );
    return UserDenorm.fromJson(_json.decode(response.body));
  }

  Future<void> deleteUser(
    String username,
    String accessToken,
  ) async {
    await makeApiCall(
      "delete",
      "/users/$username",
      authToken: accessToken,
    );
  }

  Future<Budget> createBudget(
    String username,
    String accessToken,
    CreateBudgetInput input,
  ) async {
    final response = await makeApiCall(
      "post",
      "/users/$username/budgets",
      authToken: accessToken,
      jsonBody: input.toJson(),
    );
    return Budget.fromJson(_json.decode(response.body));
  }

  Future<Budget> getBudget(
    String id,
    String username,
    String accessToken,
  ) async {
    final response = await makeApiCall(
      "get",
      "/users/$username/budgets/$id",
      authToken: accessToken,
    );
    return Budget.fromJson(_json.decode(response.body));
  }

  Future<Budget> updateBudget(
    String id,
    String username,
    String accessToken,
    UpdateBudgetInput input,
  ) async {
    if (input.isEmpty) throw UpdateEmptyException();
    final response = await makeApiCall(
      "patch",
      "/users/$username/budgets/$id",
      authToken: accessToken,
      jsonBody: input.toJson(),
    );
    return Budget.fromJson(_json.decode(response.body));
  }

  Future<void> deleteBudget(
    String id,
    String username,
    String accessToken,
  ) async {
    await makeApiCall(
      "delete",
      "/users/$username/budgets/$id",
      authToken: accessToken,
    );
  }

  Future<Category> createCategory(
    String username,
    String accessToken,
    CreateCategoryInput input,
  ) async {
    final response = await makeApiCall(
      "post",
      "/users/$username/categories",
      authToken: accessToken,
      jsonBody: input.toJson(),
    );
    return Category.fromJson(_json.decode(response.body));
  }

  Future<Category> getCategory(
    String id,
    String username,
    String accessToken,
  ) async {
    final response = await makeApiCall(
      "get",
      "/users/$username/categories/$id",
      authToken: accessToken,
    );
    return Category.fromJson(_json.decode(response.body));
  }

  Future<Category> updateCategory(
    String id,
    String username,
    String accessToken,
    UpdateCategoryInput input,
  ) async {
    if (input.isEmpty) throw UpdateEmptyException();
    final response = await makeApiCall(
      "patch",
      "/users/$username/categories/$id",
      authToken: accessToken,
      jsonBody: input.toJson(),
    );
    return Category.fromJson(_json.decode(response.body));
  }

  Future<void> deleteCategory(
    String id,
    String username,
    String accessToken,
  ) async {
    await makeApiCall(
      "delete",
      "/users/$username/categories/$id",
      authToken: accessToken,
    );
  }

  Future<Expense> createExpense(
    String username,
    String accessToken,
    CreateExpenseInput input,
  ) async {
    final response = await makeApiCall("post", "/users/$username/expenses",
        authToken: accessToken, jsonBody: input.toJson());
    return Expense.fromJson(_json.decode(response.body));
  }

  Future<Expense> getExpense(
    String id,
    String username,
    String accessToken,
  ) async {
    final response = await makeApiCall(
      "get",
      "/users/$username/expenses/$id",
      authToken: accessToken,
    );
    return Expense.fromJson(_json.decode(response.body));
  }

  Future<Expense> updateExpense(
    String id,
    String username,
    String accessToken,
    UpdateExpenseInput input,
  ) async {
    if (input.isEmpty) throw UpdateEmptyException();
    final response = await makeApiCall(
      "patch",
      "/users/$username/expenses/$id",
      authToken: accessToken,
      jsonBody: input.toJson(),
    );
    return Expense.fromJson(_json.decode(response.body));
  }

  Future<void> deleteExpense(
    String id,
    String username,
    String accessToken,
  ) async {
    await makeApiCall(
      "delete",
      "/users/$username/expenses/$id",
      authToken: accessToken,
    );
  }

  Future<http.Response> makeApiCall(
    String method,
    String path, {
    Object? jsonBody,
    String? authToken,
  }) async {
    if (!path.startsWith("/")) {
      path = "/$path";
    }
    final request = http.Request(method, Uri.parse("$_baseUrl$path"));
    if (jsonBody != null) {
      request.headers["Content-Type"] = "application/json";
      request.body = _json.encode(jsonBody);
    }
    if (authToken != null) {
      request.headers["Authorization"] = "Bearer $authToken";
    }
    try {
      final sResponse = await client.send(request);
      final response = await http.Response.fromStream(sResponse);
      // print(response.body);
      if (sResponse.statusCode >= 200 && sResponse.statusCode < 300) {
        /*  if (fromJson != null) {
        final response = await http.Response.fromStream(sResponse);
        try {
          final json = _json.decode(response.body);
          return fromJson(json);
        } catch (e) {
          throw ClientDecodingError(
              "expected response json", response.statusCode, response.body);
        }
      } */
        return response;
      } else {
        throw EndpointError.fromResponse(response, _json);
      }
    } catch (err) {
      if (err is io.SocketException) {
        throw SocketException(err);
      }
      rethrow;
    }
  }
}

class CreateUserInput {
  final String username;
  final String firebaseId;
  final String password;
  final String? email;
  final String? phoneNumber;
  final String? pictureURL;

  const CreateUserInput({
    required this.username,
    required this.firebaseId,
    required this.password,
    this.email,
    this.phoneNumber,
    this.pictureURL,
  });

  Map<String, dynamic> toJson() => {
        "username": username,
        "firebaseId": firebaseId,
        "password": password,
        "email": email,
        "phoneNumber": phoneNumber,
        "pictureURL": pictureURL,
      };
}

class UpdateUserInput {
  final int lastSeenVersion;
  final String? newUsername;
  final String? email;
  final String? phoneNumber;
  final String? password;
  final String? pictureURL;
  final String? mainBudget;

  const UpdateUserInput({
    required this.lastSeenVersion,
    this.newUsername,
    this.email,
    this.phoneNumber,
    this.password,
    this.pictureURL,
    this.mainBudget,
  });

  UpdateUserInput.fromDiff({
    required User update,
    required User old,
    this.password,
  })  : lastSeenVersion = old.version,
        newUsername = ifNotEqualTo(update.username, old.username),
        email = ifNotEqualTo(update.email, old.email),
        phoneNumber = ifNotEqualTo(update.phoneNumber, old.phoneNumber),
        mainBudget = ifNotEqualTo(update.mainBudget, old.mainBudget),
        pictureURL = ifNotEqualTo(update.pictureURL, old.pictureURL);

  Map<String, dynamic> toJson() => {
        "username": newUsername,
        "email": email,
        "phoneNumber": phoneNumber,
        "password": password,
        "pictureURL": pictureURL,
        "mainBudget": mainBudget,
        "lastSeenVersion": lastSeenVersion,
      };

  bool get isEmpty =>
      newUsername == null &&
      email == null &&
      phoneNumber == null &&
      password == null &&
      mainBudget == null &&
      pictureURL == null;
}

class CreateBudgetInput {
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final Frequency frequency;
  final MonetaryAmount allocatedAmount;
  final Map<String, int> categoryAllocations;

  const CreateBudgetInput({
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.frequency,
    required this.allocatedAmount,
    required this.categoryAllocations,
  });

  Map<String, dynamic> toJson() => {
        "name": name,
        "startTime": startTime.millisecondsSinceEpoch,
        "endTime": endTime.millisecondsSinceEpoch,
        "frequency": frequency.toJson(),
        "allocatedAmount": allocatedAmount.toJson(),
        "categoryAllocations": categoryAllocations,
      };
}

class UpdateBudgetInput {
  final int lastSeenVersion;
  final String? name;
  final DateTime? startTime;
  final DateTime? endTime;
  final Frequency? frequency;
  final MonetaryAmount? allocatedAmount;
  final Map<String, int>? categoryAllocations;
  final bool? archive;

  const UpdateBudgetInput({
    required this.lastSeenVersion,
    this.name,
    this.startTime,
    this.endTime,
    this.frequency,
    this.allocatedAmount,
    this.categoryAllocations,
    this.archive,
  });

  UpdateBudgetInput.fromDiff({
    required Budget update,
    required Budget old,
  })  : lastSeenVersion = old.version,
        name = ifNotEqualTo(update.name, old.name),
        startTime =
            (update.startTime != old.startTime || update.endTime != old.endTime)
                ? update.startTime
                : old.startTime,
        endTime =
            (update.startTime != old.startTime || update.endTime != old.endTime)
                ? update.endTime
                : old.endTime,
        frequency = ifNotEqualTo(update.frequency, old.frequency),
        allocatedAmount =
            ifNotEqualTo(update.allocatedAmount, old.allocatedAmount),
        archive = update.archivedAt != null && old.archivedAt == null,
        categoryAllocations = mapIfNotEqualTo(
            update.categoryAllocations, old.categoryAllocations);

  Map<String, dynamic> toJson() => {
        "name": name,
        "startTime": startTime?.millisecondsSinceEpoch,
        "endTime": endTime?.millisecondsSinceEpoch,
        "frequency": frequency?.toJson(),
        "allocatedAmount": allocatedAmount?.toJson(),
        "categoryAllocations": categoryAllocations,
        "archive": archive,
        "lastSeenVersion": lastSeenVersion,
      };

  bool get isEmpty =>
      name == null &&
      startTime == null &&
      endTime == null &&
      frequency == null &&
      allocatedAmount == null &&
      archive == null &&
      categoryAllocations == null;
}

class CreateCategoryInput {
  final String name;
  final List<String>? tags;
  final String? parentId;

  const CreateCategoryInput({
    required this.name,
    this.tags,
    this.parentId,
  });

  Map<String, dynamic> toJson() => {
        "name": name,
        "tags": tags,
        "parentCategory": parentId,
      };
}

class UpdateCategoryInput {
  final int lastSeenVersion;
  final String? name;
  final List<String>? tags;
  final String? parentId;
  final bool? archive;

  const UpdateCategoryInput({
    required this.lastSeenVersion,
    this.name,
    this.tags,
    this.parentId,
    this.archive,
  });

  UpdateCategoryInput.fromDiff({
    required Category update,
    required Category old,
  })  : lastSeenVersion = old.version,
        name = ifNotEqualTo(update.name, old.name),
        parentId = ifNotEqualTo(update.parentId, old.parentId),
        archive = update.archivedAt != null && old.archivedAt == null,
        tags = setINotEqualTo(update.tags.toSet(), old.tags.toSet())?.toList();

  Map<String, dynamic> toJson() => {
        "name": name,
        "tags": tags,
        "parentCategory": parentId,
        "archive": archive,
        "lastSeenVersion": lastSeenVersion,
      };

  bool get isEmpty =>
      name == null && tags == null && parentId == null && archive == null;
}

class CreateExpenseInput {
  final String name;
  final String budgetId;
  final String categoryId;
  final MonetaryAmount amount;
  final DateTime? timestamp;

  const CreateExpenseInput({
    required this.name,
    required this.budgetId,
    required this.categoryId,
    required this.amount,
    this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        "name": name,
        "amount": amount.toJson(),
        "budgetId": budgetId,
        "categoryId": categoryId,
        "timestamp": timestamp?.millisecondsSinceEpoch
      };
}

class UpdateExpenseInput {
  final int lastSeenVersion;
  final String? name;
  final MonetaryAmount? amount;
  final DateTime? timestamp;

  const UpdateExpenseInput({
    required this.lastSeenVersion,
    this.name,
    this.amount,
    this.timestamp,
  });
  UpdateExpenseInput.fromDiff({
    required Expense update,
    required Expense old,
  })  : lastSeenVersion = old.version,
        name = ifNotEqualTo(update.name, old.name),
        timestamp = ifNotEqualTo(update.timestamp, old.timestamp),
        amount = ifNotEqualTo(update.amount, old.amount);

  Map<String, dynamic> toJson() => {
        "name": name,
        "amount": amount?.toJson(),
        "timestamp": timestamp?.millisecondsSinceEpoch,
        "lastSeenVersion": lastSeenVersion,
      };

  bool get isEmpty => name == null && amount == null && timestamp == null;
}

class EndpointError {
  final int code;
  final String type;
  final Map<String, dynamic> json;

  const EndpointError(this.code, this.type, this.json);

  factory EndpointError.fromJson(Map<String, dynamic> json) => EndpointError(
        checkedConvert(json, "code", (v) => v as int),
        checkedConvert(json, "type", (v) => v as String),
        json,
      );

  factory EndpointError.fromResponse(http.Response response, JsonCodec codec) {
    late Map<String, dynamic> json;
    try {
      json = codec.decode(response.body);
    } catch (_) {
      throw ClientDecodingError(
          "expected endpoint error", response.statusCode, response.body);
    }
    final endpointErr = EndpointError.fromJson(json);
    return endpointErr;
  }
  @override
  String toString() {
    return "EndpointError( code: $code, type: $type, json: $json )";
  }
}

class ClientError implements Exception {
  final String message;

  const ClientError(this.message);
  @override
  String toString() => "ClientError( message: $message, )";
}

class ClientDecodingError extends ClientError {
  final int code;
  final String body;

  const ClientDecodingError(String message, this.code, this.body)
      : super(message);

  @override
  String toString() =>
      "DecodingClientErrror( message: $message, code: $code, body: $body )";
}

class UpdateEmptyException implements Exception {}

class SocketException implements Exception {
  final io.SocketException inner;

  SocketException(this.inner);
  @override
  String toString() => "${runtimeType.toString()} { inner: $inner }";
}

class SignInResponse {
  final String accessToken;
  final String refreshToken;
  final UserDenorm user;

  SignInResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory SignInResponse.fromJson(Map<String, dynamic> json) => SignInResponse(
        accessToken: checkedConvert(json, "accessToken", (v) => v as String),
        refreshToken: checkedConvert(json, "refreshToken", (v) => v as String),
        user: checkedConvert(json, "user",
            (v) => UserDenorm.fromJson(v as Map<String, dynamic>)),
      );
}

T dbg<T>(T item) {
  print(item);
  return item;
}

/// This returns the [value] if it's not equal to the [test]. Returns null otherwise.
T? ifNotEqualTo<T>(T? value, T? test) => value != test ? value : null;

/// This returns the [value] if it's not equal to the [test]. Returns null otherwise.
Set<T>? setINotEqualTo<T>(Set<T> value, Set<T> test) =>
    value.difference(test).isNotEmpty ? value : null;

/// This returns the [value] if it's not equal to the [test]. Returns null otherwise.
Map<K, V>? mapIfNotEqualTo<K, V>(Map<K, V> value, Map<K, V> test) {
  if (value.length != test.length) {
    return value;
  }
  for (final e in value.entries) {
    if (e.value != test[e.key]) return value;
  }
  return null;
}
