import 'dart:convert';

import 'package:http/http.dart' as http;

import './models.dart';

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

  Future<SignInRepsonse> _signIn(
    String identifierType,
    String identifier,
    String password,
  ) async {
    final response = await makeApiCall(
      "post",
      "/auth_token",
      jsonBody: {identifierType: identifier, "password": password},
    );
    return SignInRepsonse.fromJson(_json.decode(response.body));
  }

  Future<SignInRepsonse> signInEmail(
    String email,
    String password,
  ) =>
      _signIn("email", email, password);

  Future<SignInRepsonse> signInPhone(
    String phoneNumber,
    String password,
  ) =>
      _signIn("phoneNumber", phoneNumber, password);

  Future<SignInRepsonse> signInFirebaseId(
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

  Future<UserDenorm> createUser({
    required String username,
    required String firebaseId,
    required String password,
    String? email,
    String? phoneNumber,
    String? pictureURL,
  }) async {
    if (email == null && phoneNumber == null) {
      throw Exception("email or phoneNumber are required");
    }
    final response = await makeApiCall(
      "post",
      "/users",
      jsonBody: {
        "username": username,
        "firebaseId": firebaseId,
        "email": email,
        "phoneNumber": phoneNumber,
        "password": password,
        "pictureURL": pictureURL,
      },
    );
    return UserDenorm.fromJson(_json.decode(response.body));
  }

  Future<UserDenorm> updateUser(
    String username,
    String accessToken, {
    required int lastSeenVersion,
    String? newUsername,
    String? email,
    String? phoneNumber,
    String? password,
    String? pictureURL,
  }) async {
    final response = await makeApiCall(
      "patch",
      "/users/$username",
      authToken: accessToken,
      jsonBody: {
        "username": newUsername,
        "email": email,
        "phoneNumber": phoneNumber,
        "password": password,
        "pictureURL": pictureURL,
        "lastSeenVersion": lastSeenVersion,
      },
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
    String accessToken, {
    required String name,
    required DateTime startTime,
    required DateTime endTime,
    required Frequency frequency,
    required MonetaryAmount allocatedAmount,
    required Map<String, int> categoryAllocations,
  }) async {
    final response = await makeApiCall(
      "post",
      "/users/$username/budgets",
      authToken: accessToken,
      jsonBody: {
        "name": name,
        "startTime": startTime.millisecondsSinceEpoch,
        "endTime": endTime.millisecondsSinceEpoch,
        "frequency": frequency.toJson(),
        "allocatedAmount": allocatedAmount.toJson(),
        "categoryAllocations": categoryAllocations,
      },
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
    String accessToken, {
    required int lastSeenVersion,
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    Frequency? frequency,
    MonetaryAmount? allocatedAmount,
    Map<String, int>? categoryAllocations,
  }) async {
    final response = await makeApiCall(
      "patch",
      "/users/$username/budgets/$id",
      authToken: accessToken,
      jsonBody: {
        "name": name,
        "startTime": startTime?.millisecondsSinceEpoch,
        "endTime": endTime?.millisecondsSinceEpoch,
        "frequency": frequency?.toJson(),
        "allocatedAmount": allocatedAmount?.toJson(),
        "categoryAllocations": categoryAllocations,
        "lastSeenVersion": lastSeenVersion,
      },
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
    String accessToken, {
    required String name,
    required List<String>? tags,
    String? parentId,
  }) async {
    final response = await makeApiCall(
      "post",
      "/users/$username/categories",
      authToken: accessToken,
      jsonBody: {
        "name": name,
        "tags": tags,
        "parentCategory": parentId,
      },
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
    String accessToken, {
    required int lastSeenVersion,
    String? name,
    List<String>? tags,
    String? parentId,
  }) async {
    final response = await makeApiCall(
      "patch",
      "/users/$username/categories/$id",
      authToken: accessToken,
      jsonBody: {
        "name": name,
        "tags": tags,
        "parentCategory": parentId,
        "lastSeenVersion": lastSeenVersion,
      },
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
    String accessToken, {
    required String name,
    required String budgetId,
    required String categoryId,
    required MonetaryAmount amount,
  }) async {
    final response = await makeApiCall(
      "post",
      "/users/$username/expenses",
      authToken: accessToken,
      jsonBody: {
        "name": name,
        "amount": amount.toJson(),
        "budgetId": budgetId,
        "categoryId": categoryId,
      },
    );
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
    String accessToken, {
    required int lastSeenVersion,
    String? name,
    MonetaryAmount? amount,
  }) async {
    final response = await makeApiCall(
      "patch",
      "/users/$username/expenses/$id",
      authToken: accessToken,
      jsonBody: {
        "name": name,
        "amount": amount?.toJson(),
        "lastSeenVersion": lastSeenVersion,
      },
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
  }
}

T dbg<T>(T item) {
  print(item);
  return item;
}

class SignInRepsonse {
  final String accessToken;
  final String refreshToken;
  final UserDenorm user;

  SignInRepsonse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory SignInRepsonse.fromJson(Map<String, dynamic> json) => SignInRepsonse(
        accessToken: checkedConvert(json, "accessToken", (v) => v as String),
        refreshToken: checkedConvert(json, "refreshToken", (v) => v as String),
        user: checkedConvert(json, "user",
            (v) => UserDenorm.fromJson(v as Map<String, dynamic>)),
      );
}
