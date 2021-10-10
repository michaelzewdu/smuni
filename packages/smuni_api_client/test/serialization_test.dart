import 'dart:convert';

import 'package:test/test.dart';

import 'package:smuni_api_client/smuni_api_client.dart';

void main() {
  var json = JsonCodec();
  test("user de works", () {
    var user = UserDenorm.fromJson(json.decode(userJson));
    // print(user.toJson());

    expect(user.id, equals("613b67bc9aeded76daaa9b79"));
    expect(user.budgets.length, equals(2));
    expect(user.budgets[0].categoryAllocations.length, equals(2));
    expect(user.expenses.length, equals(2));
  });
}

const String userJson = """{
            "_id": "614193c7f2ea51b47f5896be",
            "username": "superkind",
            "email": "don@key.ote",
            "phoneNumber": "+251900112233",
            "pictureURL": "https://imagine.co/9q6roh3cifnp",
            "firebaseId": "ABCDEF_123456_ABCDEF_123456_",
            "budgets": [
                {
                    "name": "Monthly budget",
                    "startTime": "2021-08-31T21:00:00.000Z",
                    "endTime": "2021-09-30T21:00:00.000Z",
                    "frequency": {
                        "kind": "recurring",
                        "recurringIntervalSecs": 2592000
                    },
                    "allocatedAmount": {
                        "currency": "ETB",
                        "amount": 700000
                    },
                    "categoryAllocations": {
                        "614193c7f2ea51b47f5896b8": 100000,
                        "614193c7f2ea51b47f5896b9": 50000
                    },
                    "_id": "614193c7f2ea51b47f5896ba",
                    "createdAt": "2021-10-09T13:49:05.160Z",
                    "updatedAt": "2021-10-09T13:49:05.160Z"
                },
                {
                    "name": "Special budget",
                    "startTime": "2021-09-30T21:00:00.000Z",
                    "endTime": "2021-10-06T21:00:00.000Z",
                    "frequency": {
                        "kind": "oneTime"
                    },
                    "allocatedAmount": {
                        "currency": "ETB",
                        "amount": 1000000
                    },
                    "categoryAllocations": {},
                    "_id": "614193c7f2ea51b47f5896bb",
                    "createdAt": "2021-10-09T13:49:05.160Z",
                    "updatedAt": "2021-10-09T13:49:05.160Z"
                }
            ],
            "expenses": [
                {
                    "name": "Pill purchase",
                    "amount": {
                        "currency": "ETB",
                        "amount": 40000
                    },
                    "categoryId": "614193c7f2ea51b47f5896b9",
                    "budgetId": "614193c7f2ea51b47f5896ba",
                    "_id": "614193c7f2ea51b47f5896bc",
                    "createdAt": "2021-10-09T13:49:05.160Z",
                    "updatedAt": "2021-10-09T13:49:05.160Z"
                },
                {
                    "name": "Xanax purchase",
                    "amount": {
                        "currency": "ETB",
                        "amount": 20000
                    },
                    "categoryId": "614193c7f2ea51b47f5896b8",
                    "budgetId": "614193c7f2ea51b47f5896ba",
                    "_id": "614193c7f2ea51b47f5896bd",
                    "createdAt": "2021-10-09T13:49:05.160Z",
                    "updatedAt": "2021-10-09T13:49:05.160Z"
                }
            ],
            "payoffPlans": [],
            "categories": [
                {
                    "name": "Medicine",
                    "tags": [
                        "pharma"
                    ],
                    "_id": "614193c7f2ea51b47f5896b8",
                    "createdAt": "2021-10-09T13:49:05.161Z",
                    "updatedAt": "2021-10-09T13:49:05.161Z"
                },
                {
                    "name": "RejuvPill",
                    "parentCategory": {
                        "_id": "614193c7f2ea51b47f5896b8",
                        "name": "Medicine"
                    },
                    "tags": [],
                    "_id": "614193c7f2ea51b47f5896b9",
                    "createdAt": "2021-10-09T13:49:05.161Z",
                    "updatedAt": "2021-10-09T13:49:05.161Z"
                }
            ],
            "createdAt": "2021-10-09T13:49:05.162Z",
            "updatedAt": "2021-10-09T13:49:05.162Z"
        }""";
