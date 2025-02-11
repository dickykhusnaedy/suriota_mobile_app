import 'package:flutter/material.dart';

extension CustomTextTheme on BuildContext {
  TextStyle get h1 => Theme.of(this).textTheme.titleLarge!;
  TextStyle get h2 => Theme.of(this).textTheme.titleMedium!;
  TextStyle get h3 => Theme.of(this).textTheme.titleSmall!;
  TextStyle get h4 => Theme.of(this).textTheme.headlineLarge!;
  TextStyle get h5 => Theme.of(this).textTheme.headlineMedium!;
  TextStyle get h6 => Theme.of(this).textTheme.headlineSmall!;
  TextStyle get body => Theme.of(this).textTheme.bodyMedium!;
  TextStyle get bodySmall => Theme.of(this).textTheme.bodySmall!;
  TextStyle get buttonText => Theme.of(this).textTheme.labelLarge!;
  TextStyle get buttonTextSmall => Theme.of(this).textTheme.labelMedium!;
  TextStyle get buttonTextSmallest => Theme.of(this).textTheme.labelSmall!;
}
