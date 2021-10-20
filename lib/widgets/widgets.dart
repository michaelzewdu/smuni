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
