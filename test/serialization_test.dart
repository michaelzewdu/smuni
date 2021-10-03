import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:smuni/models/models.dart';

void main() {
  var json = JsonCodec();
  test("user de works", () {
    var user = User.fromJson(json.decode(USER_JSON));
    // print(user.toJSON());

    expect(user.id, equals("613b67bc9aeded76daaa9b79"));
    expect(user.budgets.length, equals(2));
    expect(user.budgets[0].categoryAllocation.length, equals(2));
    expect(user.expenses.length, equals(2));
  });
}

const String USER_JSON = """{
        "_id": "614193c7f2ea51b47f5896be",
        "username": "superkind",
        "email": "don@key.ote",
        "phoneNumber": "+251900112233",
        "pictureURL": "https://imagine.co/9q6roh3cifnp",
        "firebaseId": "ABCDEF_123456_ABCDEF_123456_",
        "budgets": [
            {
                "frequency": {
                    "kind": "recurring",
                    "recurringIntervalSecs": 2592000
                },
                "allocatedAmount": {
                    "currency": "ETB",
                    "amount": 700000
                },
                "name": "Monthly budget",
                "startTime": "2021-07-31T21:00:00.000Z",
                "endTime": "2021-08-31T21:00:00.000Z",
                "categories": [
                    {
                        "allocatedAmount": {
                            "currency": "ETB",
                            "amount": 100000
                        },
                        "name": "Medicine",
                        "tags": [
                            "pharma"
                        ],
                        "_id": "614193c7f2ea51b47f5896b8",
                        "createdAt": "2021-09-15T06:33:45.553Z",
                        "updatedAt": "2021-09-15T06:33:45.553Z"
                    },
                    {
                        "allocatedAmount": {
                            "currency": "ETB",
                            "amount": 50000
                        },
                        "name": "RejuvPill",
                        "parentCategory": {
                            "_id": "614193c7f2ea51b47f5896b8",
                            "name": "Medicine"
                        },
                        "tags": [],
                        "_id": "614193c7f2ea51b47f5896b9",
                        "createdAt": "2021-09-15T06:33:45.553Z",
                        "updatedAt": "2021-09-15T06:33:45.553Z"
                    }
                ],
                "_id": "614193c7f2ea51b47f5896ba",
                "createdAt": "2021-09-15T06:33:45.554Z",
                "updatedAt": "2021-09-15T06:33:45.554Z"
            },
            {
                "frequency": {
                    "kind": "oneTime"
                },
                "allocatedAmount": {
                    "currency": "ETB",
                    "amount": 1000000
                },
                "name": "Special budget",
                "startTime": "2021-08-31T21:00:00.000Z",
                "endTime": "2021-09-06T21:00:00.000Z",
                "categories": [],
                "_id": "614193c7f2ea51b47f5896bb",
                "createdAt": "2021-09-15T06:33:45.554Z",
                "updatedAt": "2021-09-15T06:33:45.554Z"
            }
        ],
        "expenses": [
            {
                "amount": {
                    "currency": "ETB",
                    "amount": 40000
                },
                "name": "Pill purchase",
                "category": {
                    "_id": "614193c7f2ea51b47f5896b9",
                    "budgetId": "614193c7f2ea51b47f5896ba"
                },
                "_id": "614193c7f2ea51b47f5896bc",
                "createdAt": "2021-09-15T06:33:45.554Z",
                "updatedAt": "2021-09-15T06:33:45.554Z"
            },
            {
                "amount": {
                    "currency": "ETB",
                    "amount": 20000
                },
                "name": "Xanax purchase",
                "category": {
                    "_id": "614193c7f2ea51b47f5896b8",
                    "budgetId": "614193c7f2ea51b47f5896ba"
                },
                "_id": "614193c7f2ea51b47f5896bd",
                "createdAt": "2021-09-15T06:33:45.554Z",
                "updatedAt": "2021-09-15T06:33:45.554Z"
            }
        ],
        "payoffPlans": [],
        "createdAt": "2021-09-15T06:33:45.555Z",
        "updatedAt": "2021-09-15T06:33:45.555Z"
    }""";
