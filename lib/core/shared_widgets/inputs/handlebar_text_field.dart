import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';

import '../../../app/design-system/spacing.dart';

/// A reusable text field Widget with the Handlebar theme
class HandlebarTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final bool isEnabled;
  final bool isObscured;
  final TextInputType? inputType;
  final Function(String)? onChanged;
  final Widget? prefix;
  final Widget? suffix;
  final double minHeight;
  final String? Function(String?)? validator;

  const HandlebarTextField(
      {super.key,
      required this.controller,
      this.hint,
      this.isEnabled = true,
      required this.isObscured,
      this.inputType,
      this.label,
      this.onChanged,
      this.prefix,
      this.suffix,
      this.minHeight = Spacing.token48,
      this.validator});

  static const _borderWidth = 1.4;
  static const _focusedBorderWidth = 1.8;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: isEnabled,
      decoration: InputDecoration(
          isDense: true,
          labelText: label,
          hintText: hint,
          prefixIcon: prefix,
          suffixIcon: suffix,
          filled: true,
          fillColor: context.colorScheme.surface,
          contentPadding: EdgeInsets.symmetric(
            vertical: (minHeight - 24).clamp(0, double.infinity) / 2,
            horizontal: 12,
          ),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(
                  color: context.colorScheme.outline, width: _borderWidth)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(
                  color: context.colorScheme.outline,
                  width: _focusedBorderWidth))),
      keyboardType: inputType,
      obscureText: isObscured,
      onChanged: onChanged,
      validator: validator,
    );
  }
}
