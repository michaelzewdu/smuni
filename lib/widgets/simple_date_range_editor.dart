import 'package:flutter/material.dart';

import 'package:smuni/utilities.dart';

class SimpleDateRangeFormEditor extends FormField<DateRange> {
  SimpleDateRangeFormEditor({
    Key? key,
    Widget? caption,
    DateRange? initialValue,
    FormFieldSetter<DateRange>? onSaved,
    void Function(DateRange?)? onChanged,
    FormFieldValidator<DateRange>? validator,
    // AutovalidateMode? autovalidateMode,
    // bool? enabled,
    String? restorationId,
    List<DateRangeFilter>? rangesToShow,
  }) : super(
          key: key,
          initialValue: initialValue,
          validator: validator,
          onSaved: onSaved,
          restorationId: restorationId,
          builder: (state) => SimpleDateRangeEditor(
            caption: state.errorText != null
                ? Text(state.errorText!, style: TextStyle(color: Colors.red))
                : caption,
            initialValue: state.value,
            rangesToShow: rangesToShow,
            onChanged: (value) {
              state.didChange(value);
              onChanged?.call(value);
            },
          ),
        );
}

class SimpleDateRangeEditor extends StatefulWidget {
  // late final Frequency initialFrequency;
  late final DateRange initialValue;
  late final List<DateRangeFilter> rangesToShow;
  final void Function(DateRange)? onChanged;
  final Widget? caption;
  SimpleDateRangeEditor({
    Key? key,
    DateRange? initialValue,
    List<DateRangeFilter>? rangesToShow,
    this.onChanged,
    this.caption,
    // this.initialFrequency = const OneTime(),
  })  : initialValue = initialValue ?? DateRange.monthRange(DateTime.now()),
        rangesToShow = rangesToShow ?? [],
        super(key: key);

  @override
  _SimpleDateRangeEditorState createState() => _SimpleDateRangeEditorState();
}

class _SimpleDateRangeEditorState extends State<SimpleDateRangeEditor> {
  // late bool _isOneTime = widget.initialFrequency is OneTime;
  late DateRange _range = widget.initialValue;
  late DateRangeFilter custom = DateRangeFilter(
    "Custom",
    widget.initialValue,
    FilterLevel.custom,
  );

  @override
  Widget build(context) => Column(
        children: [
          if (widget.caption != null) widget.caption!,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            // TODO: auto scroll to selected chip
            // controller: ScrollController(),
            child: Row(
              children: [
                SizedBox(width: 16),
                ChoiceChip(
                  selected: !widget.rangesToShow.any((e) => e.range == _range),
                  onSelected: (_) async {
                    final range = await showDateRangePicker(
                      context: context,
                      helpText: "Custom Budget Day Range",
                      fieldStartLabelText: "Start Date",
                      fieldEndLabelText: "End Date",
                      initialEntryMode: DatePickerEntryMode.input,
                      initialDateRange: custom.range.toFlutter(),
                      firstDate: DateTime.fromMillisecondsSinceEpoch(0),
                      lastDate:
                          DateTime.fromMillisecondsSinceEpoch(8640000000000000),
                    );
                    if (range != null) {
                      setState(() {
                        custom = DateRangeFilter(
                          "Custom",
                          DateRange.fromFlutter(range),
                          FilterLevel.custom,
                        );
                        _range = DateRange.fromFlutter(range);
                        widget.onChanged?.call(_range);
                      });
                    }
                  },
                  label: Row(children: const [
                    Icon(Icons.arrow_downward),
                    Text("Custom")
                  ]),
                ),
                ...widget.rangesToShow.map(
                  (e) => Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: ChoiceChip(
                      selected: _range == e.range,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _range = e.range;
                            widget.onChanged?.call(_range);
                          });
                        }
                      },
                      label: Text(e.name),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  /*  Widget selectorTextField() => TextFormField(
        controller: dateController,
        readOnly: true,
        autofocus: true,
        decoration: InputDecoration(
            hintText: fieldName,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffix: IconButton(
              autofocus: true,
              icon: Icon(Icons.calendar_today),
              onPressed: () async {
                if (fieldName == 'Start Date') {
                  DateTime? pickedDay = await showDatePicker(
                      context: context,
                      helpText: helpText,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(9999));
                  _startDate = pickedDay;
                  if (pickedDay != null)
                    dateController.text =
                        '${pickedDay.month.toString()}/${pickedDay.day.toString()}/${pickedDay.year.toString()}';
                } else if (fieldName == 'End Date') {
                  if (_startDate == null) {
                    var snackBar =
                        SnackBar(content: Text("Choose start day first"));
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    return;
                  }
                  DateTime? pickedDay = await showDatePicker(
                      context: context,
                      helpText: helpText,
                      initialDate: _startDate!,
                      firstDate: _startDate!,
                      lastDate: DateTime(9999));
                  _endDate = pickedDay;
                  if (pickedDay != null)
                    dateController.text =
                        '${pickedDay.month.toString()}/${pickedDay.day.toString()}/${pickedDay.year.toString()}';
                }
              },
            )),
      ); */
}
