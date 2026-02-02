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
import '../../features/attendance/data/datasources/attendance_local_data_source.dart'
    as _i769;
import '../../features/attendance/data/repositories/attendance_repository_impl.dart'
    as _i719;
import '../../features/attendance/domain/repositories/attendance_repository.dart'
    as _i477;
import '../../features/attendance/domain/usecases/generate_attendance_report_usecase.dart'
    as _i296;
import '../../features/attendance/domain/usecases/get_weekly_attendance_usecase.dart'
    as _i891;
import '../../features/attendance/domain/usecases/save_attendance_usecase.dart'
    as _i763;
import '../../features/attendance/presentation/controllers/attendance_entry_controller.dart'
    as _i507;
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
import '../../features/classes/domain/usecases/get_class_by_id_usecase.dart'
    as _i526;
import '../../features/classes/domain/usecases/get_classes_usecase.dart'
    as _i1015;
import '../../features/classes/domain/usecases/get_evaluations_usecase.dart'
    as _i859;
import '../../features/home/domain/usecases/fetch_and_store_user_usecase.dart'
    as _i82;
import '../../features/print/data/services/excel_export_service.dart' as _i552;
import '../../features/print/data/services/pdf_export_service.dart' as _i191;
import '../../features/print/data/services/qr_pdf_service.dart' as _i951;
import '../../features/print/domain/usecases/generate_attendance_report_usecase.dart'
    as _i763;
import '../../features/print/domain/usecases/generate_multi_week_attendance_report_usecase.dart'
    as _i871;
import '../../features/print/domain/usecases/generate_multi_week_scores_report_usecase.dart'
    as _i968;
import '../../features/print/domain/usecases/generate_scores_report_usecase.dart'
    as _i51;
import '../../features/reports/domain/usecases/get_class_report_usecase.dart'
    as _i564;
import '../../features/students/data/repositories/student_repository_impl.dart'
    as _i865;
import '../../features/students/domain/repositories/student_repository.dart'
    as _i679;
import '../../features/students/domain/usecases/add_student_usecase.dart'
    as _i891;
import '../../features/students/domain/usecases/delete_student_usecase.dart'
    as _i965;
import '../../features/students/domain/usecases/edit_student_usecase.dart'
    as _i958;
import '../../features/students/domain/usecases/get_student_by_id_usecase.dart'
    as _i925;
import '../../features/students/domain/usecases/get_student_by_qr_code_usecase.dart'
    as _i171;
import '../../features/students/domain/usecases/get_student_details_with_scores_usecase.dart'
    as _i982;
import '../../features/students/domain/usecases/get_students_by_class_id_usecase.dart'
    as _i346;
import '../../features/students/domain/usecases/get_students_usecase.dart'
    as _i623;
import '../../features/students/domain/usecases/update_student_score_usecase.dart'
    as _i203;
import '../../features/students/presentation/controllers/bulk_score_entry_controller.dart'
    as _i1037;
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
    gh.factory<_i552.ExcelExportService>(() => _i552.ExcelExportService());
    gh.factory<_i191.PdfExportService>(() => _i191.PdfExportService());
    gh.factory<_i951.QrPdfService>(() => _i951.QrPdfService());
    gh.singleton<_i748.DatabaseService>(() => _i748.DatabaseService());
    gh.singleton<_i1018.SecureStorageService>(
      () => _i1018.SecureStorageService(),
    );
    await gh.singletonAsync<_i285.StorageService>(() {
      final i = _i285.StorageService();
      return i.init().then((_) => i);
    }, preResolve: true);
    gh.factory<_i769.AttendanceLocalDataSource>(
      () => _i769.AttendanceLocalDataSource(gh<_i748.DatabaseService>()),
    );
    gh.lazySingleton<_i679.StudentRepository>(
      () => _i865.StudentRepositoryImpl(gh<_i748.DatabaseService>()),
    );
    gh.lazySingleton<_i367.ClassRepository>(
      () => _i972.ClassRepositoryImpl(gh<_i748.DatabaseService>()),
    );
    gh.lazySingleton<_i171.GetStudentByQrCodeUseCase>(
      () => _i171.GetStudentByQrCodeUseCase(gh<_i679.StudentRepository>()),
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
    gh.factory<_i526.GetClassByIdUseCase>(
      () => _i526.GetClassByIdUseCase(gh<_i367.ClassRepository>()),
    );
    gh.factory<_i1015.GetClassesUseCase>(
      () => _i1015.GetClassesUseCase(gh<_i367.ClassRepository>()),
    );
    gh.factory<_i859.GetEvaluationsUseCase>(
      () => _i859.GetEvaluationsUseCase(gh<_i367.ClassRepository>()),
    );
    gh.factory<_i564.GetClassReportUseCase>(
      () => _i564.GetClassReportUseCase(
        gh<_i679.StudentRepository>(),
        gh<_i367.ClassRepository>(),
      ),
    );
    gh.singleton<_i1009.AuthInterceptor>(
      () => _i1009.AuthInterceptor(gh<_i1018.SecureStorageService>()),
    );
    gh.factory<_i891.AddStudentUseCase>(
      () => _i891.AddStudentUseCase(gh<_i679.StudentRepository>()),
    );
    gh.factory<_i965.DeleteStudentUseCase>(
      () => _i965.DeleteStudentUseCase(gh<_i679.StudentRepository>()),
    );
    gh.factory<_i958.EditStudentUseCase>(
      () => _i958.EditStudentUseCase(gh<_i679.StudentRepository>()),
    );
    gh.factory<_i925.GetStudentByIdUseCase>(
      () => _i925.GetStudentByIdUseCase(gh<_i679.StudentRepository>()),
    );
    gh.factory<_i982.GetStudentDetailsWithScoresUseCase>(
      () => _i982.GetStudentDetailsWithScoresUseCase(
        gh<_i679.StudentRepository>(),
      ),
    );
    gh.factory<_i346.GetStudentsByClassIdUseCase>(
      () => _i346.GetStudentsByClassIdUseCase(gh<_i679.StudentRepository>()),
    );
    gh.factory<_i623.GetStudentsUseCase>(
      () => _i623.GetStudentsUseCase(gh<_i679.StudentRepository>()),
    );
    gh.factory<_i203.UpdateStudentScoreUseCase>(
      () => _i203.UpdateStudentScoreUseCase(gh<_i679.StudentRepository>()),
    );
    gh.factory<_i477.AttendanceRepository>(
      () =>
          _i719.AttendanceRepositoryImpl(gh<_i769.AttendanceLocalDataSource>()),
    );
    gh.factory<_i891.GetWeeklyAttendanceUseCase>(
      () => _i891.GetWeeklyAttendanceUseCase(
        gh<_i477.AttendanceRepository>(),
        gh<_i679.StudentRepository>(),
      ),
    );
    gh.lazySingleton<_i361.Dio>(
      () => networkModule.dio(gh<_i1009.AuthInterceptor>()),
    );
    gh.factory<_i763.SaveAttendanceUseCase>(
      () => _i763.SaveAttendanceUseCase(gh<_i477.AttendanceRepository>()),
    );
    gh.factory<_i507.AttendanceEntryController>(
      () => _i507.AttendanceEntryController(
        gh<_i1015.GetClassesUseCase>(),
        gh<_i526.GetClassByIdUseCase>(),
        gh<_i891.GetWeeklyAttendanceUseCase>(),
        gh<_i763.SaveAttendanceUseCase>(),
      ),
    );
    gh.factory<_i1037.BulkScoreEntryController>(
      () => _i1037.BulkScoreEntryController(
        gh<_i526.GetClassByIdUseCase>(),
        gh<_i859.GetEvaluationsUseCase>(),
        gh<_i346.GetStudentsByClassIdUseCase>(),
        gh<_i203.UpdateStudentScoreUseCase>(),
        gh<_i171.GetStudentByQrCodeUseCase>(),
      ),
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
    gh.lazySingleton<_i315.LicenseRemoteDataSource>(
      () => _i315.LicenseRemoteDataSourceImpl(gh<_i738.ApiService>()),
    );
    gh.factory<_i763.GenerateAttendanceReportUseCase>(
      () => _i763.GenerateAttendanceReportUseCase(
        gh<_i679.StudentRepository>(),
        gh<_i367.ClassRepository>(),
        gh<_i926.UserRepository>(),
      ),
    );
    gh.factory<_i968.GenerateMultiWeekScoresReportUseCase>(
      () => _i968.GenerateMultiWeekScoresReportUseCase(
        gh<_i679.StudentRepository>(),
        gh<_i367.ClassRepository>(),
        gh<_i926.UserRepository>(),
      ),
    );
    gh.factory<_i51.GenerateScoresReportUseCase>(
      () => _i51.GenerateScoresReportUseCase(
        gh<_i679.StudentRepository>(),
        gh<_i367.ClassRepository>(),
        gh<_i926.UserRepository>(),
      ),
    );
    gh.factory<_i296.GenerateWeeklyAttendanceReportUseCase>(
      () => _i296.GenerateWeeklyAttendanceReportUseCase(
        gh<_i477.AttendanceRepository>(),
        gh<_i367.ClassRepository>(),
        gh<_i679.StudentRepository>(),
        gh<_i926.UserRepository>(),
      ),
    );
    gh.factory<_i871.GenerateMultiWeekAttendanceReportUseCase>(
      () => _i871.GenerateMultiWeekAttendanceReportUseCase(
        gh<_i477.AttendanceRepository>(),
        gh<_i367.ClassRepository>(),
        gh<_i679.StudentRepository>(),
        gh<_i926.UserRepository>(),
      ),
    );
    gh.lazySingleton<_i107.AuthRemoteDataSource>(
      () => _i107.AuthRemoteDataSourceImpl(gh<_i738.ApiService>()),
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
    gh.factory<_i435.SignInUseCase>(
      () => _i435.SignInUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i611.SignOutUseCase>(
      () => _i611.SignOutUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i57.SignUpUseCase>(
      () => _i57.SignUpUseCase(gh<_i787.AuthRepository>()),
    );
    gh.lazySingleton<_i1066.LicenseRepository>(
      () => _i167.LicenseRepositoryImpl(
        gh<_i315.LicenseRemoteDataSource>(),
        gh<_i285.StorageService>(),
        gh<_i1018.SecureStorageService>(),
      ),
    );
    gh.factory<_i253.RedeemCouponUseCase>(
      () => _i253.RedeemCouponUseCase(gh<_i1066.LicenseRepository>()),
    );
    return this;
  }
}

class _$NetworkModule extends _i567.NetworkModule {}
