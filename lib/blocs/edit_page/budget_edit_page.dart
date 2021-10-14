import 'package:smuni/models/models.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

import 'edit_page.dart';
// EVENTS

typedef BudgetEditPageBlocEvent
    = EditPageBlocEvent<String, Budget, CreateBudgetInput, UpdateBudgetInput>;
typedef UpdateBudget
    = UpdateItem<String, Budget, CreateBudgetInput, UpdateBudgetInput>;
typedef CreateBudget
    = CreateItem<String, Budget, CreateBudgetInput, UpdateBudgetInput>;

// STATE
typedef BudgetEditPageBlocState
    = EditPageBlocState<String, Budget, CreateBudgetInput, UpdateBudgetInput>;
typedef BudgetEditFailed
    = EditFailed<String, Budget, CreateBudgetInput, UpdateBudgetInput>;
typedef BudgetEditSuccess
    = EditSuccess<String, Budget, CreateBudgetInput, UpdateBudgetInput>;

// BLOC

typedef BudgetEditPageBloc
    = EditPageBloc<String, Budget, CreateBudgetInput, UpdateBudgetInput>;
