import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moalem/core/constants/app_routes.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/features/auth/presentation/controllers/auth_controller.dart';
import 'package:moalem/features/classes/presentation/screens/classes_screen.dart';
import 'package:moalem/features/home/presentation/controllers/home_controller.dart';
import 'package:moalem/features/print/presentation/screens/print_screen.dart';
import 'package:moalem/features/profile/presentation/screens/profile_screen.dart';
import 'package:moalem/features/reports/presentation/screens/reports_screen.dart';
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
    ref.listen<AsyncValue<bool>>(homeControllerProvider, (previous, next) {
      if (next is AsyncData<bool> && !next.value) {
        context.go(AppRoutes.activation);
      }
    });

    final state = ref.watch(homeControllerProvider);

    return state.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (_) {
        return AppBottomNavigationBar(
          controller: _controller,
          screens: [
            _buildHomeScreen(),
            const ClassesScreen(),
            const PrintScreen(),
            const ReportsScreen(),
            const ProfileScreen(),
          ],
        );
      },
    );
  }

  Widget _buildHomeScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.navHome.tr()),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
              context.go(AppRoutes.signIn);
            },
          ),
        ],
      ),
      body: Center(child: Text(AppStrings.navHome.tr())),
    );
  }
}
