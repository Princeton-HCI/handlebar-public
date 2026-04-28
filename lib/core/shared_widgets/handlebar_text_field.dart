import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';

import '../../app/design-system/spacing.dart';

class HandlebarTextField extends StatefulWidget {
  final String? label;
  final TextEditingController controller;

  final bool isRequired;
  final bool isPassword;
  final bool isReadOnly;
  final bool enableInteractiveSelection;
  final bool enabled;
  final TextInputType keyboardType;
  final int maxLines;
  final TextCapitalization textCapitalization;

  final String? hintText;
  final Iterable<String>? autofillHints;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final IconData? prefixIcon;
  final FocusNode? focusNode;

  const HandlebarTextField({
    super.key,
    required this.controller,
    this.label,
    this.keyboardType = TextInputType.text,
    this.isRequired = true,
    this.isPassword = false,
    this.isReadOnly = false,
    this.enableInteractiveSelection = true,
    this.enabled = true,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.hintText,
    this.autofillHints,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onTap,
    this.suffixIcon,
    this.prefixIcon,
    this.focusNode,
  });

  @override
  State<HandlebarTextField> createState() => _HandlebarTextFieldState();
}

class _HandlebarTextFieldState extends State<HandlebarTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    // Toggle for passwords vs custom icon
    final Widget? suffixWidget = widget.isPassword
        ? IconButton(
            padding: const EdgeInsets.all(Spacing.token8),
            onPressed: widget.enabled
                ? () {
                    setState(() {
                      _obscure = !_obscure;
                    });
                  }
                : null,
            icon: Icon(
              _obscure ? Icons.visibility_off : Icons.visibility,
              color: widget.enabled
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          )
        : widget.suffixIcon;

    final hasLabel = widget.label != null && widget.label!.trim().isNotEmpty;

    final field = TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      maxLines: _obscure ? 1 : widget.maxLines,
      autofillHints: widget.autofillHints,
      validator: widget.validator,
      focusNode: widget.focusNode,
      obscureText: _obscure,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      onFieldSubmitted: widget.onFieldSubmitted,
      readOnly: widget.isReadOnly,
      enabled: widget.enabled,
      onTap: widget.enabled ? widget.onTap : null,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        prefixIcon: widget.prefixIcon != null
            ? Icon(
                widget.prefixIcon,
                size: 20,
                color: theme.colorScheme.onSurface,
              )
            : null,
        suffixIcon: suffixWidget != null
            ? Padding(
                padding: const EdgeInsets.only(right: Spacing.token8),
                child: suffixWidget,
              )
            : null,
      ),
    );

    if (!hasLabel) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: widget.label!,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: widget.enabled
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            children: [
              if (widget.isRequired)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.token8),
        field,
      ],
    );
  }
}
