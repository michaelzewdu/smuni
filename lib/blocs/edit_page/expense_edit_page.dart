import 'package:smuni/models/models.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

import 'edit_page.dart';
// EVENTS

typedef ExpenseEditPageBlocEvent = EditPageBlocEvent<String, Expense,
    CreateExpenseInput, UpdateExpenseInput>;
typedef UpdateExpense
    = UpdateItem<String, Expense, CreateExpenseInput, UpdateExpenseInput>;
typedef CreateExpense
    = CreateItem<String, Expense, CreateExpenseInput, UpdateExpenseInput>;

// STATE
typedef ExpenseEditPageBlocState = EditPageBlocState<String, Expense,
    CreateExpenseInput, UpdateExpenseInput>;
typedef ExpenseEditFailed
    = EditFailed<String, Expense, CreateExpenseInput, UpdateExpenseInput>;
typedef ExpenseEditSuccess
    = EditSuccess<String, Expense, CreateExpenseInput, UpdateExpenseInput>;

// BLOC

typedef ExpenseEditPageBloc
    = EditPageBloc<String, Expense, CreateExpenseInput, UpdateExpenseInput>;
