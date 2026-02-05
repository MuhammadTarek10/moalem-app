import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moalem/core/constants/app_routes.dart';
import 'package:moalem/core/entities/user.dart';
import 'package:moalem/core/utils/error_handler.dart';
import 'package:moalem/core/utils/license_checker.dart';
import 'package:moalem/features/classes/presentation/screens/classes_screen.dart';
import 'package:moalem/features/home/presentation/controllers/home_controller.dart';
import 'package:moalem/features/home/presentation/pages/home_screen.dart';
import 'package:moalem/features/print/presentation/screens/print_screen.dart';
import 'package:moalem/features/profile/presentation/screens/profile_screen.dart';
import 'package:moalem/features/reports/presentation/screens/reports_screen.dart';
import 'package:moalem/shared/screens/error_screen.dart';
import 'package:moalem/shared/screens/loading_screen.dart';
import 'package:moalem/shared/widgets/bottom_navigation_bar.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  late PersistentTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeControllerProvider.notifier).fetchAndStoreUser();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<User?>>(homeControllerProvider, (previous, next) {
      next.whenData((user) {
        if (user != null &&
            !LicenseChecker.isLicenseValid(user.licenseExpiresAt)) {
          context.go(AppRoutes.activation);
        }
      });
    });

    final state = ref.watch(homeControllerProvider);

    return state.when(
      loading: () => const LoadingScreen(),
      error: (err, stack) => ErrorScreen(
        message: ErrorHandler.getErrorMessage(err),
        onRetry: () =>
            ref.read(homeControllerProvider.notifier).fetchAndStoreUser(),
      ),
      data: (_) {
        return AppBottomNavigationBar(
          controller: _controller,
          screens: [
            const HomeScreen(),
            const ClassesScreen(),
            const PrintScreen(),
            const ReportsScreen(),
            const ProfileScreen(),
          ],
        );
      },
    );
  }
}
