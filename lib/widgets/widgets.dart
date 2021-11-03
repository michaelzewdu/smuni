export 'budget_list_view.dart';
export 'budget_selector.dart';
export 'category_list_view.dart';
export 'category_selector.dart';
export 'expense_list_view.dart';
export 'money_editor.dart';

import 'package:flutter/material.dart';

class DotSeparator extends StatelessWidget {
  const DotSeparator({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Icon(
          Icons.circle_rounded,
          size: 8,
        ),
      );
}
