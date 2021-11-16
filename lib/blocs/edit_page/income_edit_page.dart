import 'package:smuni/models/models.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

import 'edit_page.dart';
// EVENTS

typedef IncomeEditPageBlocEvent
    = EditPageBlocEvent<String, Income, CreateIncomeInput, UpdateIncomeInput>;
typedef UpdateIncome
    = UpdateItem<String, Income, CreateIncomeInput, UpdateIncomeInput>;
typedef CreateIncome
    = CreateItem<String, Income, CreateIncomeInput, UpdateIncomeInput>;

// STATE
typedef IncomeEditPageBlocState
    = EditPageBlocState<String, Income, CreateIncomeInput, UpdateIncomeInput>;
typedef IncomeEditFailed
    = EditFailed<String, Income, CreateIncomeInput, UpdateIncomeInput>;
typedef IncomeEditSuccess
    = EditSuccess<String, Income, CreateIncomeInput, UpdateIncomeInput>;

// BLOC

typedef IncomeEditPageBloc
    = EditPageBloc<String, Income, CreateIncomeInput, UpdateIncomeInput>;
