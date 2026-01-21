import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

extension NavigatorExtension on BuildContext {
  void pushNewScreen(Widget screen) {
    PersistentNavBarNavigator.pushNewScreen(
      this,
      screen: screen,
      withNavBar: true,
    );
  }
}

extension TextThemeExtension on BuildContext {
  TextStyle get headlineLarge => Theme.of(this).textTheme.headlineLarge!;
  TextStyle get headlineMedium => Theme.of(this).textTheme.headlineMedium!;
  TextStyle get headlineSmall => Theme.of(this).textTheme.headlineSmall!;
  TextStyle get titleLarge => Theme.of(this).textTheme.titleLarge!;
  TextStyle get titleMedium => Theme.of(this).textTheme.titleMedium!;
  TextStyle get titleSmall => Theme.of(this).textTheme.titleSmall!;
  TextStyle get bodyLarge => Theme.of(this).textTheme.bodyLarge!;
  TextStyle get bodyMedium => Theme.of(this).textTheme.bodyMedium!;
  TextStyle get bodySmall => Theme.of(this).textTheme.bodySmall!;
}

extension SizeExtension on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
}

extension ColorSchemeExtension on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  Color get primaryColor => colorScheme.primary;
  Color get secondaryColor => colorScheme.secondary;
  Color get surfaceColor => colorScheme.surface;
  Color get errorColor => colorScheme.error;
  Color get textPrimaryColor => colorScheme.onPrimary;
  Color get textSecondaryColor => colorScheme.onSecondary;
  Color get textSurfaceColor => colorScheme.onSurface;
  Color get textErrorColor => colorScheme.onError;
}

extension SnackBarExtension on BuildContext {
  ScaffoldMessengerState get scaffoldMessenger => ScaffoldMessenger.of(this);
  void showSnackBar(SnackBar snackBar) =>
      scaffoldMessenger.showSnackBar(snackBar);
  void showTextSnackBar(String message) {
    scaffoldMessenger.removeCurrentSnackBar();
    scaffoldMessenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void showErrorSnackBar(String message) {
    scaffoldMessenger.removeCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  void showSuccessSnackBar(String message) {
    scaffoldMessenger.removeCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
    );
  }

  void showInfoSnackBar(String message) {
    scaffoldMessenger.removeCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
