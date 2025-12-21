// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/activation/data/datasources/license_remote_data_source.dart'
    as _i315;
import '../../features/activation/data/repositories/license_repository_impl.dart'
    as _i167;
import '../../features/activation/domain/repositories/license_repository.dart'
    as _i1066;
import '../../features/activation/domain/usecases/redeem_coupon_usecase.dart'
    as _i253;
import '../../features/auth/data/datasources/auth_remote_data_source.dart'
    as _i107;
import '../../features/auth/data/datasources/user_remote_data_source.dart'
    as _i886;
import '../../features/auth/data/repositories/auth_repository_impl.dart'
    as _i153;
import '../../features/auth/data/repositories/user_repository_impl.dart'
    as _i687;
import '../../features/auth/domain/repositories/auth_repository.dart' as _i787;
import '../../features/auth/domain/repositories/user_repository.dart' as _i926;
import '../../features/auth/domain/usecases/signin_usecase.dart' as _i435;
import '../../features/auth/domain/usecases/signout_usecase.dart' as _i611;
import '../../features/auth/domain/usecases/signup_usecase.dart' as _i57;
import '../../features/classes/data/repositories/class_repository_impl.dart'
    as _i972;
import '../../features/classes/domain/repositories/class_repository.dart'
    as _i367;
import '../../features/classes/domain/usecases/add_class_usecase.dart'
    as _i1053;
import '../../features/classes/domain/usecases/delete_class_usecase.dart'
    as _i639;
import '../../features/classes/domain/usecases/edit_class_usecase.dart'
    as _i397;
import '../../features/classes/domain/usecases/get_classes_usecase.dart'
    as _i1015;
import '../../features/home/domain/usecases/fetch_and_store_user_usecase.dart'
    as _i82;
import 'api_service.dart' as _i738;
import 'auth_interceptor.dart' as _i1009;
import 'database_service.dart' as _i748;
import 'network_module.dart' as _i567;
import 'secure_storage_service.dart' as _i1018;
import 'storage_service.dart' as _i285;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final networkModule = _$NetworkModule();
    gh.singleton<_i748.DatabaseService>(() => _i748.DatabaseService());
    gh.singleton<_i1018.SecureStorageService>(
      () => _i1018.SecureStorageService(),
    );
    await gh.singletonAsync<_i285.StorageService>(() {
      final i = _i285.StorageService();
      return i.init().then((_) => i);
    }, preResolve: true);
    gh.lazySingleton<_i367.ClassRepository>(
      () => _i972.ClassRepositoryImpl(gh<_i748.DatabaseService>()),
    );
    gh.factory<_i1053.AddClassUseCase>(
      () => _i1053.AddClassUseCase(gh<_i367.ClassRepository>()),
    );
    gh.factory<_i639.DeleteClassUseCase>(
      () => _i639.DeleteClassUseCase(gh<_i367.ClassRepository>()),
    );
    gh.factory<_i397.EditClassUseCase>(
      () => _i397.EditClassUseCase(gh<_i367.ClassRepository>()),
    );
    gh.factory<_i1015.GetClassesUseCase>(
      () => _i1015.GetClassesUseCase(gh<_i367.ClassRepository>()),
    );
    gh.singleton<_i1009.AuthInterceptor>(
      () => _i1009.AuthInterceptor(gh<_i1018.SecureStorageService>()),
    );
    gh.lazySingleton<_i361.Dio>(
      () => networkModule.dio(gh<_i1009.AuthInterceptor>()),
    );
    gh.lazySingleton<_i738.ApiService>(
      () => networkModule.apiService(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i886.UserRemoteDataSource>(
      () => _i886.UserRemoteDataSourceImpl(gh<_i738.ApiService>()),
    );
    gh.lazySingleton<_i926.UserRepository>(
      () => _i687.UserRepositoryImpl(
        gh<_i886.UserRemoteDataSource>(),
        gh<_i285.StorageService>(),
      ),
    );
    gh.lazySingleton<_i107.AuthRemoteDataSource>(
      () => _i107.AuthRemoteDataSourceImpl(gh<_i738.ApiService>()),
    );
    gh.lazySingleton<_i315.LicenseRemoteDataSource>(
      () => _i315.LicenseRemoteDataSourceImpl(gh<_i738.ApiService>()),
    );
    gh.lazySingleton<_i787.AuthRepository>(
      () => _i153.AuthRepositoryImpl(
        gh<_i107.AuthRemoteDataSource>(),
        gh<_i285.StorageService>(),
        gh<_i1018.SecureStorageService>(),
      ),
    );
    gh.factory<_i82.FetchAndStoreUserUseCase>(
      () => _i82.FetchAndStoreUserUseCase(
        gh<_i926.UserRepository>(),
        gh<_i1018.SecureStorageService>(),
        gh<_i285.StorageService>(),
      ),
    );
    gh.lazySingleton<_i1066.LicenseRepository>(
      () => _i167.LicenseRepositoryImpl(
        gh<_i315.LicenseRemoteDataSource>(),
        gh<_i285.StorageService>(),
        gh<_i1018.SecureStorageService>(),
      ),
    );
    gh.factory<_i435.SignInUseCase>(
      () => _i435.SignInUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i611.SignOutUseCase>(
      () => _i611.SignOutUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i57.SignUpUseCase>(
      () => _i57.SignUpUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i253.RedeemCouponUseCase>(
      () => _i253.RedeemCouponUseCase(gh<_i1066.LicenseRepository>()),
    );
    return this;
  }
}

class _$NetworkModule extends _i567.NetworkModule {}
