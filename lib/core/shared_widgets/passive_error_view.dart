import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';

import '../../app/design-system/spacing.dart';
import 'handlebar_button.dart';

class PassiveErrorView extends StatelessWidget {
  final String? message;
  final String? subtitle;
  final VoidCallback onRetry;

  /// If true, renders a tiny "Chip-like" error (perfect for Dropdowns/Selectors).
  /// If false, renders a full "Empty State" style error (perfect for full screens or lists).
  final bool isCompact;

  const PassiveErrorView({
    super.key,
    this.message,
    this.subtitle,
    required this.onRetry,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final scheme = theme.colorScheme;
    final msg = message ?? 'Error loading data';

    // --- COMPACT MODE (For Selectors / Chips) ---
    if (isCompact) {
      return InkWell(
        onTap: onRetry,
        borderRadius: BorderRadius.circular(Spacing.token8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: Spacing.token12,
            vertical: Spacing.token8,
          ),
          decoration: BoxDecoration(
            color: scheme.errorContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(Spacing.token8),
            border: Border.all(color: scheme.error.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh_rounded, size: 14, color: scheme.error),
              Spacing.hSpace8,
              Text(
                msg,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // --- FULL MODE (For Main Content / Lists) ---
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.token24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Floating Error Icon
            Container(
              padding: const EdgeInsets.all(Spacing.token16),
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 32,
                color: scheme.error,
              ),
            ),
            Spacing.vSpace16,

            // Main Error Message
            Text(
              msg,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            Spacing.vSpace8,

            // Contextual Subtitle
            Text(
              subtitle ??
                  "We couldn't connect to the server.\nPlease try again.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            Spacing.vSpace24,

            // Handlebar Primary Retry Button
            HandlebarButton.primary(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
