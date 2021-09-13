import 'dart:convert';

import 'package:smuni/models/models.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  var json = JsonCodec();
  test("user de works", () {
    var user = User.fromJson(json.decode(USER_JSON));
    print(user.toJSON());
    assert(user.id == "613b67bc9aeded76daaa9b79");
    assert(user.budgets.length == 2);
    assert(user.budgets[0].categories.length == 2);
    assert(user.expenses.length == 2);
  });
}

const String USER_JSON = """{
        "_id": "613b67bc9aeded76daaa9b79",
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
                        "_id": "613b67bc9aeded76daaa9b73",
                        "createdAt": "2021-09-10T14:12:13.191Z",
                        "updatedAt": "2021-09-10T14:12:13.191Z"
                    },
                    {
                        "allocatedAmount": {
                            "currency": "ETB",
                            "amount": 50000
                        },
                        "name": "RejuvPill",
                        "parentCategory": {
                            "_id": "613b67bc9aeded76daaa9b73",
                            "name": "Medicine"
                        },
                        "tags": [],
                        "_id": "613b67bc9aeded76daaa9b74",
                        "createdAt": "2021-09-10T14:12:13.191Z",
                        "updatedAt": "2021-09-10T14:12:13.191Z"
                    }
                ],
                "_id": "613b67bc9aeded76daaa9b75",
                "createdAt": "2021-09-10T14:12:13.191Z",
                "updatedAt": "2021-09-10T14:12:13.191Z"
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
                "_id": "613b67bc9aeded76daaa9b76",
                "createdAt": "2021-09-10T14:12:13.191Z",
                "updatedAt": "2021-09-10T14:12:13.191Z"
            }
        ],
        "incomes": [],
        "expenses": [
            {
                "amount": {
                    "currency": "ETB",
                    "amount": 40000
                },
                "name": "Pill purchase",
                "category": {
                    "_id": "613b67bc9aeded76daaa9b74",
                    "name": "RejuvPill",
                    "budgetId": "613b67bc9aeded76daaa9b75",
                    "budgetName": "Monthly budget"
                },
                "_id": "613b67bc9aeded76daaa9b77",
                "createdAt": "2021-09-10T14:12:13.192Z",
                "updatedAt": "2021-09-10T14:12:13.192Z"
            },
            {
                "amount": {
                    "currency": "ETB",
                    "amount": 40000
                },
                "name": "Pill purchase",
                "category": {
                    "_id": "613b67bc9aeded76daaa9b74",
                    "name": "RejuvPill",
                    "budgetId": "613b67bc9aeded76daaa9b75",
                    "budgetName": "Monthly budget"
                },
                "_id": "613b67bc9aeded76daaa9b77",
                "createdAt": "2021-09-10T14:12:13.192Z",
                "updatedAt": "2021-09-10T14:12:13.192Z"
            }
        ],
        "payoffPlans": [],
        "createdAt": "2021-09-10T14:12:13.192Z",
        "updatedAt": "2021-09-10T14:12:13.192Z"
    }""";
