# Project gitስሙኒ

\(￣︶￣*\))

## To-do

- [ ] Search feature for the list pages
- [ ] Optional add category button on CategoryListView
- [x] Date Picker bug on budget edit
- [ ] Budget switch is buggy
- [x] Item archival
- [ ] Expense name suggestions
- [ ] Pull to refresh 
- [ ] Text wrap(We can use the softWrap and overWrap parameters)
  
- [x] Decide on how to tackle deletion
- [ ] Decide on how to aggregate budget usage in the category tree
- [ ] Get rid of CacheSynchronizer
- [ ] On app level build.gradle Warning:(40, 9) Not targeting the latest versions of Android; compatibility modes apply. Consider testing and updating this version. Consult the android.os.Build.VERSION_CODES javadoc for details.
## Design doc

### Entities thinking map

- Expense: committed expenditure 
- Budget: planned expense
- Debt payoff plan: special type of budget

### Screens

- [ ] Sign up
- [ ] Login
- [x] Home
- [ ] Settings
- [x] Budgets List
- [x] Budget Details
- [x] Budget Add/Edit
- [x] Expenses List
- [x] Expense Details
- [x] Expense Add/Edit
- [x] Categort list
- [x] Category details
- [x] Category Add/Edit
- [ ] Dept payoff plans list
- [ ] Dept payoff plans details
- [ ] Dept payoff plans add 
- [ ] Dept payoff plans edit
- [ ] Finance 

### Flutter Blocs

- [ ] Sign up bloc
- [ ] Sign in bloc
- [ ] User bloc
- [x] Budgets list/search bloc
- [x] Budget details/edit bloc
- [x] Expense list/search bloc
- [x] Expense details/edit bloc
- [x] Category list/search bloc
- [x] Category details/edit bloc
- [ ] Dept payoff list/search bloc
- [ ] Dept payoff details/edit bloc
- [ ] Finance bloc

### Features


## dev-log

### Offline first

Right now, we're using a CacheSyncronizer entity to send all offline updates one by one to the server during sync. This class has very brittle code and here, the identified concerns when modifying it are listed:

- operation ordering: you can't add expenses to budgets that don't exist, can you?
- operation failure: if network buckles after succefully updating a category, we need to update all related budgets and whatnot
- offline operations: some CRUD operations affect other entities, when doing them online, we need to do the same on the items in the local cache