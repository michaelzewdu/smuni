import 'package:smuni/models/models.dart';
import 'package:smuni_api_client/smuni_api_client.dart';

import 'edit_page.dart';
// EVENTS

typedef CategoryEditPageBlocEvent = EditPageBlocEvent<String, Category,
    CreateCategoryInput, UpdateCategoryInput>;
typedef UpdateCategory
    = UpdateItem<String, Category, CreateCategoryInput, UpdateCategoryInput>;
typedef CreateCategory
    = CreateItem<String, Category, CreateCategoryInput, UpdateCategoryInput>;

// STATE
typedef CategoryEditPageBlocState = EditPageBlocState<String, Category,
    CreateCategoryInput, UpdateCategoryInput>;
typedef CategoryEditFailed
    = EditFailed<String, Category, CreateCategoryInput, UpdateCategoryInput>;
typedef CategoryEditSuccess
    = EditSuccess<String, Category, CreateCategoryInput, UpdateCategoryInput>;

// BLOC

typedef CategoryEditPageBloc
    = EditPageBloc<String, Category, CreateCategoryInput, UpdateCategoryInput>;
