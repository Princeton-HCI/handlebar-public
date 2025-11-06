import 'dart:ui';

import 'package:flutter/material.dart';

/// Design-system responsive layout parameters
class LayoutTheme extends ThemeExtension<LayoutTheme> {
  final double? maxContentWidth;
  final double tabletBreakpoint;
  final EdgeInsets topLevelScreenPadding;

  const LayoutTheme(
      {required this.tabletBreakpoint,
      required this.topLevelScreenPadding,
      this.maxContentWidth});

  @override
  ThemeExtension<LayoutTheme> copyWith(
      {double? tabletBreakpoint,
      EdgeInsets? topLevelScreenPadding,
      double? maxContentWidth}) {
    return LayoutTheme(
        tabletBreakpoint: tabletBreakpoint ?? this.tabletBreakpoint,
        topLevelScreenPadding:
            topLevelScreenPadding ?? this.topLevelScreenPadding,
        maxContentWidth: maxContentWidth ?? this.maxContentWidth);
  }

  @override
  ThemeExtension<LayoutTheme> lerp(
      covariant ThemeExtension<LayoutTheme>? other, double t) {
    if (other is! LayoutTheme) return this;
    return LayoutTheme(
        tabletBreakpoint:
            lerpDouble(tabletBreakpoint, other.tabletBreakpoint, t)!,
        topLevelScreenPadding: EdgeInsets.lerp(
            topLevelScreenPadding, other.topLevelScreenPadding, t)!,
        maxContentWidth: lerpDouble(maxContentWidth, other.maxContentWidth, t));
  }
}

/// Mobile layout preset
const LayoutTheme layoutMobile = LayoutTheme(
    tabletBreakpoint: 700.0,
    topLevelScreenPadding:
        EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
    maxContentWidth: null);

/// Tablet layout preset
const LayoutTheme layoutTablet = LayoutTheme(
    tabletBreakpoint: 700.0,
    topLevelScreenPadding:
        EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
    maxContentWidth: 550.0);
