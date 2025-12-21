import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moalem/core/constants/app_routes.dart';
import 'package:moalem/features/activation/presentation/screens/activation_screen.dart';
import 'package:moalem/features/auth/presentation/screens/auth_screen.dart';
import 'package:moalem/features/auth/presentation/screens/signin_screen.dart';
import 'package:moalem/features/auth/presentation/screens/signup_screen.dart';
import 'package:moalem/features/home/presentation/pages/main_navigation_screen.dart';
import 'package:moalem/features/profile/presentation/screens/advanced_settings_screen.dart';
import 'package:moalem/features/profile/presentation/screens/contact_us_screen.dart';
import 'package:moalem/features/profile/presentation/screens/profile_details_screen.dart';
import 'package:moalem/features/profile/presentation/screens/rate_us_screen.dart';
import 'package:moalem/features/splash/presentation/pages/splash_screen.dart';
import 'package:moalem/shared/screens/error_screen.dart';

final router = GoRouter(
  initialLocation: AppRoutes.splash,
  errorBuilder: (context, state) => ErrorScreen(
    message: state.error?.message,
    onGoBack: () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        GoRouter.of(context).go(AppRoutes.splash);
      }
    },
  ),
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.auth,
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: AppRoutes.signIn,
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: AppRoutes.signUp,
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: AppRoutes.activation,
      builder: (context, state) => const ActivationScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const MainNavigationScreen(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfileDetailsScreen(),
    ),
    GoRoute(
      path: AppRoutes.advancedSettings,
      builder: (context, state) => const AdvancedSettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.rateUs,
      builder: (context, state) => const RateUsScreen(),
    ),
    GoRoute(
      path: AppRoutes.contactUs,
      builder: (context, state) => const ContactUsScreen(),
    ),
  ],
);
