import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:smuni/models/models.dart';

class MoneyEditor extends StatelessWidget {
  final MonetaryAmount initial;
  final void Function(int) onSavedWhole;
  final void Function(int) onSavedCents;

  const MoneyEditor({
    Key? key,
    required this.onSavedWhole,
    required this.onSavedCents,
    this.initial = const MonetaryAmount(currency: "ETB", amount: 0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: TextFormField(
              textAlign: TextAlign.end,
              keyboardType: TextInputType.numberWithOptions(),
              initialValue: (initial.amount / 100).truncate().toString(),
              onSaved: (value) {
                onSavedWhole(int.parse(value!));
              },
              validator: (value) {
                if (value == null || int.tryParse(value) == null) {
                  return "Must be a whole number";
                }
              },
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: "Amount",
                helperText: "Amount",
                prefix: const Text("ETB"),
              ),
            ),
          ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.3,
            ),
            child: TextFormField(
              inputFormatters: [LengthLimitingTextInputFormatter(2)],
              keyboardType: TextInputType.numberWithOptions(),
              initialValue: (initial.amount % 100).toString(),
              onSaved: (value) {
                onSavedCents(int.parse(value!));
              },
              validator: (value) {
                if (value == null || int.tryParse(value) == null) {
                  return "Not a whole number";
                }
              },
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: "Cents",
                helperText: "Cents",
              ),
            ),
          ),
        ],
      );
}
