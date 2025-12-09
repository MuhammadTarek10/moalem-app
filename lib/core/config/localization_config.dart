import 'package:flutter/material.dart';

class LocalizationConfig {
  static const List<Locale> supportedLocales = [
    Locale('ar'),
    // Locale('en'), // Uncomment when adding English support
  ];

  static const String path = 'assets/translations';
  static const Locale fallbackLocale = Locale('ar');
  static const Locale startLocale = Locale('ar');

  static bool isRTL(BuildContext context) {
    return Directionality.of(context) == TextDirection.rtl;
  }
}
