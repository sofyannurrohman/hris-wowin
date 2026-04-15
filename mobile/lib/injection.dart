import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hris_app/core/network/api_client.dart';
import 'package:hris_app/core/services/biometric_service.dart';
import 'package:hris_app/core/services/local_database_service.dart';

import 'package:hris_app/features/kpi/domain/repositories/kpi_repository.dart';
import 'package:hris_app/features/kpi/data/repositories/kpi_repository_impl.dart';
import 'package:hris_app/features/kpi/presentation/bloc/kpi_bloc.dart';
import 'package:hris_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:hris_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:hris_app/features/auth/domain/usecases/auth_usecases.dart';
import 'package:hris_app/features/auth/domain/usecases/biometric_usecases.dart';
import 'package:hris_app/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:hris_app/features/leave/domain/repositories/leave_repository.dart';
import 'package:hris_app/features/leave/data/repositories/leave_repository_impl.dart';
import 'package:hris_app/features/leave/domain/usecases/leave_usecases.dart';
import 'package:hris_app/features/leave/presentation/bloc/leave_bloc.dart';

import 'package:hris_app/features/attendance/data/repositories/attendance_repository.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:hris_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:hris_app/features/overtime/data/repositories/overtime_repository.dart';
import 'package:hris_app/features/overtime/presentation/bloc/overtime_bloc.dart';

import 'package:hris_app/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:hris_app/features/payroll/data/repositories/payroll_repository_impl.dart';
import 'package:hris_app/features/payroll/domain/usecases/get_payslip_history_usecase.dart';
import 'package:hris_app/features/payroll/presentation/bloc/payroll_bloc.dart';
import 'package:hris_app/features/reimbursement/domain/repositories/reimbursement_repository.dart';
import 'package:hris_app/features/reimbursement/data/repositories/reimbursement_repository_impl.dart';
import 'package:hris_app/features/reimbursement/presentation/bloc/reimbursement_bloc.dart';
import 'package:hris_app/features/approval/presentation/bloc/approval_bloc.dart';
import 'package:hris_app/features/announcement/data/repositories/announcement_repository.dart';
import 'package:hris_app/features/announcement/presentation/bloc/announcement_bloc.dart';
import 'package:hris_app/features/directory/data/repositories/directory_repository.dart';
import 'package:hris_app/features/directory/presentation/bloc/directory_bloc.dart';
import 'package:hris_app/features/schedule/data/repositories/shift_repository.dart';
import 'package:hris_app/features/schedule/presentation/bloc/shift_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => const FlutterSecureStorage());

  // Core
  sl.registerLazySingleton(() => ApiClient(prefs: sl()));
  sl.registerLazySingleton(() => BiometricService());
  sl.registerLazySingleton(() => LocalDatabaseService());

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      apiClient: sl(), 
      prefs: sl(),
      biometricService: sl(),
      secureStorage: sl(),
    ),
  );
  sl.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepository(
      apiClient: sl(),
      localDb: sl(),
    ),
  );
  sl.registerLazySingleton<LeaveRepository>(
    () => LeaveRepositoryImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<OvertimeRepository>(
    () => OvertimeRepository(apiClient: sl()),
  );
  sl.registerLazySingleton<PayrollRepository>(
    () => PayrollRepositoryImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<ReimbursementRepository>(
    () => ReimbursementRepositoryImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<KPIRepository>(
    () => KPIRepositoryImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<AnnouncementRepository>(
    () => AnnouncementRepositoryImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<DirectoryRepository>(
    () => DirectoryRepositoryImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<ShiftRepository>(
    () => ShiftRepositoryImpl(apiClient: sl()),
  );

  // UseCases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => CheckAuthStatusUseCase(sl()));
  sl.registerLazySingleton(() => RegisterFaceUseCase(sl()));
  sl.registerLazySingleton(() => SubmitLeaveUseCase(sl()));
  sl.registerLazySingleton(() => GetMyLeavesUseCase(sl()));
  sl.registerLazySingleton(() => GetAllLeavesUseCase(sl()));
  sl.registerLazySingleton(() => ApproveLeaveUseCase(sl()));
  sl.registerLazySingleton(() => GetLeaveBalancesUseCase(sl()));
  sl.registerLazySingleton(() => GetMyPayslipHistoryUseCase(sl()));
  sl.registerLazySingleton(() => BiometricLoginUseCase(sl()));
  sl.registerLazySingleton(() => GetBiometricStatusUseCase(sl()));
  sl.registerLazySingleton(() => SetBiometricEnabledUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      logoutUseCase: sl(),
      checkAuthStatusUseCase: sl(),
      registerFaceUseCase: sl(),
      biometricLoginUseCase: sl(),
      getBiometricStatusUseCase: sl(),
      setBiometricEnabledUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => AttendanceBloc(
      repository: sl(),
      authRepository: sl(),
    ),
  );
  sl.registerFactory(
    () => LeaveBloc(
      submitLeaveUseCase: sl(),
      getMyLeavesUseCase: sl(),
      getAllLeavesUseCase: sl(),
      approveLeaveUseCase: sl(),
      getLeaveBalancesUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => ProfileBloc(authRepository: sl()),
  );
  sl.registerFactory(
    () => OvertimeBloc(repository: sl()),
  );
  sl.registerFactory(
    () => PayrollBloc(getMyPayslipHistoryUseCase: sl()),
  );
  sl.registerFactory(
    () => ReimbursementBloc(repository: sl()),
  );
  sl.registerFactory(
    () => KPIBloc(repository: sl()),
  );
  sl.registerFactory(
    () => ApprovalBloc(leaveRepository: sl(), reimbursementRepository: sl()),
  );
  sl.registerFactory(
    () => AnnouncementBloc(repository: sl()),
  );
  sl.registerFactory(
    () => DirectoryBloc(repository: sl()),
  );
  sl.registerFactory(
    () => ShiftBloc(repository: sl()),
  );
}
