import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moalem/core/constants/app_routes.dart';
import 'package:moalem/features/activation/presentation/screens/activation_screen.dart';
import 'package:moalem/features/activation/presentation/screens/second_activation_screen.dart';
import 'package:moalem/features/attendance/presentation/screens/attendance_entry_screen.dart';
import 'package:moalem/features/auth/presentation/screens/auth_screen.dart';
import 'package:moalem/features/auth/presentation/screens/signin_screen.dart';
import 'package:moalem/features/auth/presentation/screens/signup_screen.dart';
import 'package:moalem/features/classes/presentation/screens/class_details_screen.dart';
import 'package:moalem/features/classes/presentation/screens/classes_screen.dart';
import 'package:moalem/features/home/presentation/pages/main_navigation_screen.dart';
import 'package:moalem/features/print/presentation/screens/print_options_screen.dart';
import 'package:moalem/features/print/presentation/screens/qr_print_screen.dart';
import 'package:moalem/features/profile/presentation/screens/advanced_settings_screen.dart';
import 'package:moalem/features/profile/presentation/screens/contact_us_screen.dart';
import 'package:moalem/features/profile/presentation/screens/profile_details_screen.dart';
import 'package:moalem/features/profile/presentation/screens/rate_us_screen.dart';
import 'package:moalem/features/reports/presentation/screens/reports_screen.dart';
import 'package:moalem/features/splash/presentation/pages/splash_screen.dart';
import 'package:moalem/features/students/presentation/screens/bulk_score_entry_screen.dart';
import 'package:moalem/features/students/presentation/screens/student_details_screen.dart';
import 'package:moalem/shared/screens/error_screen.dart';

final router = GoRouter(
  initialLocation: AppRoutes.splash,
  errorBuilder: (context, state) => ErrorScreen(
    message: state.error?.message,
    onGoBack: () {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.splash);
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
      path: AppRoutes.activationStepTwo,
      builder: (context, state) => const SecondActivationScreen(),
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
    GoRoute(
      path: AppRoutes.classes,
      builder: (context, state) => const ClassesScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) =>
              ClassDetailsScreen(id: state.pathParameters['id']!),
        ),
        GoRoute(
          path: ':id/bulk-scores',
          builder: (context, state) =>
              BulkScoreEntryScreen(classId: state.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.studentDetails,
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) =>
              StudentDetailsScreen(studentId: state.pathParameters['id']!),
        ),
      ],
      builder: (context, state) => const SizedBox.shrink(),
    ),
    GoRoute(
      path: AppRoutes.reports,
      builder: (context, state) {
        final classId = state.uri.queryParameters['classId'];
        return ReportsScreen(classId: classId);
      },
    ),
    GoRoute(
      path: AppRoutes.printOptions,
      builder: (context, state) {
        final classId = state.uri.queryParameters['classId'];
        final printType = state.uri.queryParameters['printType'];
        return PrintOptionsScreen(
          classId: classId ?? '',
          printType: printType ?? 'scores',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.qrPrint,
      builder: (context, state) => const QrPrintScreen(),
    ),
    GoRoute(
      path: AppRoutes.attendanceEntry,
      builder: (context, state) {
        final classId = state.uri.queryParameters['classId'];
        return AttendanceEntryScreen(classId: classId);
      },
    ),
  ],
);
