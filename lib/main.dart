import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app/app_theme.dart';
import 'app/router.dart';
import 'core/config/localization_config.dart';
import 'core/constants/app_routes.dart';
import 'core/services/injection.dart';
import 'core/services/license_service.dart';
import 'features/auth/domain/repositories/auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await ScreenUtil.ensureScreenSize();
  await configureDependencies();

  runApp(
    EasyLocalization(
      supportedLocales: LocalizationConfig.supportedLocales,
      path: LocalizationConfig.path,
      fallbackLocale: LocalizationConfig.fallbackLocale,
      startLocale: LocalizationConfig.startLocale,
      child: const ProviderScope(child: MyApp()),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _initLicenseMonitoring();
  }

  void _initLicenseMonitoring() {
    // Initialize LicenseService
    final licenseService = getIt<LicenseService>();
    licenseService.init();

    // Listen for expiration events
    licenseService.onLicenseExpired.listen((_) async {
      // Clear auth data
      final authRepository = getIt<AuthRepository>();
      await authRepository.signOut();

      // Navigate to login
      if (mounted) {
        // We use the global router instance to navigate context-free if needed,
        // or we can use ref/context if available.
        // Since router is a global variable in app/router.dart, we can use it directly
        // or via context if we are in the tree.
        router.go(AppRoutes.signIn);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Standard mobile design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Mr Assistant',
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: LocalizationConfig.startLocale,
          theme: AppTheme.lightTheme,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
