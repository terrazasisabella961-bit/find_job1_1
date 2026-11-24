import 'package:flutter/material.dart';

import 'app_bottom_navigation.dart';

class FormFieldLabel extends StatelessWidget {
  const FormFieldLabel(
    this.text, {
    this.required = true,
    this.style,
    this.padding = const EdgeInsets.only(bottom: 6),
    super.key,
  });

  final String text;
  final bool required;
  final TextStyle? style;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final labelStyle = style ??
        TextStyle(
          color: appTextColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        );
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(child: Text(text, style: labelStyle)),
          Text(
            required ? ' *' : ' (opcional)',
            style: labelStyle.copyWith(
              color: required ? const Color(0xFFFF4D6D) : appMutedColor,
              fontWeight: required ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
