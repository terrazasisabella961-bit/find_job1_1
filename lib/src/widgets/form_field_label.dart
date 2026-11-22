import 'package:flutter/material.dart';

import 'app_bottom_navigation.dart';

class FormFieldLabel extends StatelessWidget {
  const FormFieldLabel(
    this.text, {
    this.required = true,
    this.style = const TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
    this.padding = const EdgeInsets.only(bottom: 6),
    super.key,
  });

  final String text;
  final bool required;
  final TextStyle style;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(child: Text(text, style: style)),
          Text(
            required ? ' *' : ' (opcional)',
            style: style.copyWith(
              color: required ? const Color(0xFFFF4D6D) : appMutedColor,
              fontWeight: required ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
