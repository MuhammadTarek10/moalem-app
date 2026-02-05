import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app/app_theme.dart';
import 'app/router.dart';
import 'core/config/localization_config.dart';
import 'core/services/injection.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
