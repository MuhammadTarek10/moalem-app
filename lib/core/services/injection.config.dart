// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import 'database_service.dart' as _i748;
import 'secure_storage_service.dart' as _i1018;
import 'storage_service.dart' as _i285;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.singleton<_i748.DatabaseService>(() => _i748.DatabaseService());
    gh.singleton<_i1018.SecureStorageService>(
      () => _i1018.SecureStorageService(),
    );
    await gh.singletonAsync<_i285.StorageService>(() {
      final i = _i285.StorageService();
      return i.init().then((_) => i);
    }, preResolve: true);
    return this;
  }
}
