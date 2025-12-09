import 'package:go_router/go_router.dart';

import '../features/splash/presentation/pages/splash_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
  ],
);
