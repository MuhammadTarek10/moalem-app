import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:moalem/core/services/license_service.dart';

import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init', // default
  preferRelativeImports: true, // default
  asExtension: true, // default
)
Future<void> configureDependencies() async {
  await getIt.init();
  getIt.registerSingleton(LicenseService(getIt()));
}
