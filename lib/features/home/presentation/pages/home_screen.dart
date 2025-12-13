import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moalem/core/constants/app_routes.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/features/auth/presentation/controllers/auth_controller.dart';
import 'package:moalem/features/home/presentation/controllers/home_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeControllerProvider.notifier).fetchAndStoreUser();
    });
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
        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.appTitle.tr()),
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
          body: Center(child: Text(AppStrings.welcome.tr())),
        );
      },
    );
  }
}
