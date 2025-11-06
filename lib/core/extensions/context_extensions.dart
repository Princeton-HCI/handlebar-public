import 'package:flutter/material.dart';

import '../../app/design-system/layout_theme.dart';

/// Context extensions based on the Theme
extension ThemeExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);

  LayoutTheme get layout => theme.extension<LayoutTheme>()!;

  ColorScheme get colorScheme => theme.colorScheme;
}

/// Context extensions based on the typography
extension TypographyExtensions on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;

  // ----- Hero text -----
  TextStyle? get displayLarge => textTheme.displayLarge;
  TextStyle? get displayMedium => textTheme.displayMedium;
  TextStyle? get displaySmall => textTheme.displaySmall;

  // ----- Section headers text -----
  TextStyle? get headlineLarge => textTheme.headlineLarge;
  TextStyle? get headlineMedium => textTheme.headlineMedium;
  TextStyle? get headlineSmall => textTheme.headlineSmall;

  // ----- Section sub-headers text -----
  TextStyle? get titleLarge => textTheme.titleLarge;
  TextStyle? get titleMedium => textTheme.titleMedium;
  TextStyle? get titleSMall => textTheme.titleSmall;

  // ----- General text -----
  TextStyle? get bodyLarge => textTheme.bodyLarge;
  TextStyle? get bodyMedium => textTheme.bodyMedium;
  TextStyle? get bodySmall => textTheme.bodySmall;

  // ----- Label text -----
  TextStyle? get labelLarge => textTheme.labelLarge;
  TextStyle? get labelMedium => textTheme.labelMedium;
  TextStyle? get labelSmall => textTheme.labelSmall;
}

/// Context extensions based on the device type
extension DeviceExtensions on BuildContext {
  Size get size => MediaQuery.sizeOf(this);

  double get width => size.width;
  double get height => size.height;

  bool get isTablet => width >= layout.tabletBreakpoint;

  double get scaler {
    final width = MediaQuery.of(this).size.width;
    if (width >= layout.tabletBreakpoint) return 1.3;
    return 1.0;
  }

  double scaled(double base) => base * scaler;
}
