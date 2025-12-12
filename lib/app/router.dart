import 'package:go_router/go_router.dart';
import 'package:moalem/core/constants/app_routes.dart';
import 'package:moalem/features/auth/presentation/screens/auth_screen.dart';
import 'package:moalem/features/auth/presentation/screens/signin_screen.dart';
import 'package:moalem/features/auth/presentation/screens/signup_screen.dart';
import 'package:moalem/features/home/presentation/pages/home_screen.dart';
import 'package:moalem/features/splash/presentation/pages/splash_screen.dart';

final router = GoRouter(
  initialLocation: AppRoutes.splash,
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
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
