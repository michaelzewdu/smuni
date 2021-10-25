import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:smuni/models/models.dart';

class MoneyFormEditor extends FormField<MonetaryAmount> {
  MoneyFormEditor({
    Key? key,
    Widget? caption,
    MonetaryAmount? initialValue,
    FormFieldSetter<MonetaryAmount>? onSaved,
    void Function(MonetaryAmount?)? onChanged,
    FormFieldValidator<MonetaryAmount>? validator,
    AutovalidateMode? autovalidateMode,
    // bool? enabled,
    String? restorationId,
  }) : super(
          key: key,
          initialValue: initialValue,
          validator: validator,
          onSaved: onSaved,
          restorationId: restorationId,
          autovalidateMode: autovalidateMode,
          builder: (state) => MoneyEditor(
            caption: state.errorText != null
                ? Text(state.errorText!, style: TextStyle(color: Colors.red))
                : caption,
            amount:
                state.value ?? const MonetaryAmount(currency: "ETB", amount: 0),
            onChanged: (value) {
              state.didChange(value);
              onChanged?.call(value);
            },
          ),
        );
}

class MoneyEditor extends StatelessWidget {
  final MonetaryAmount amount;
  final void Function(MonetaryAmount)? onChanged;
  final Widget? caption;

  const MoneyEditor({
    Key? key,
    this.onChanged,
    this.caption,
    required this.amount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          if (caption != null) caption!,
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  textAlign: TextAlign.end,
                  keyboardType: TextInputType.numberWithOptions(),
                  initialValue: amount.wholes.toString(),
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null) {
                      final newAmount = MonetaryAmount(
                          currency: amount.currency,
                          amount: parsed * 100 + amount.cents);
                      onChanged?.call(newAmount);
                    }
                  },
                  validator: (value) {
                    if (value == null || int.tryParse(value) == null) {
                      return "Must be a whole number";
                    }
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8))),
                    hintText: "Amount",
                    helperText: "Amount",
                    prefix: const Text("ETB"),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.3,
                  ),
                  child: TextFormField(
                    inputFormatters: [LengthLimitingTextInputFormatter(2)],
                    keyboardType: TextInputType.numberWithOptions(),
                    initialValue: amount.cents.toString(),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null) {
                        final newAmount = MonetaryAmount(
                            currency: amount.currency,
                            amount: amount.wholes * 100 + parsed);
                        onChanged?.call(newAmount);
                      }
                    },
                    validator: (value) {
                      if (value == null || int.tryParse(value) == null) {
                        return "Invalid";
                      }
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8))),
                      hintText: "Cents",
                      helperText: "Cents",
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
}
