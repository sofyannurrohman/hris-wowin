import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_app/injection.dart' as di;
import 'package:hris_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hris_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:hris_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:hris_app/features/leave/presentation/bloc/leave_bloc.dart';
import 'package:hris_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:hris_app/features/home/presentation/pages/home_page.dart';
import 'package:hris_app/features/auth/presentation/pages/login_page.dart';
import 'package:hris_app/features/auth/presentation/pages/splash_screen.dart';
import 'package:hris_app/core/theme/app_theme.dart';
import 'package:hris_app/core/network/api_client.dart';
import 'package:hris_app/core/services/notification_service.dart';
import 'package:hris_app/features/announcement/presentation/bloc/announcement_bloc.dart';
import 'package:hris_app/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:hris_app/features/schedule/presentation/bloc/shift_bloc.dart';
import 'package:hris_app/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:hris_app/features/sales/presentation/pages/sales_dashboard_page.dart';
import 'package:hris_app/features/sales/presentation/pages/delivery_dashboard_page.dart';
import 'package:hris_app/core/utils/dialog_utils.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await di.init();
  
  // Initialize notifications
  final notificationService = di.sl<NotificationService>();
  await notificationService.init();
  await notificationService.requestPermissions();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authBloc = di.sl<AuthBloc>()..add(CheckAuthStatusRequested());

    // Listen for global 401 Unauthorized events
    di.sl<ApiClient>().onUnauthorized.listen((_) {
      authBloc.add(SessionExpired());
    });

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => authBloc,
        ),
        BlocProvider(
          create: (_) => di.sl<AttendanceBloc>(),
        ),
        BlocProvider(
          create: (_) => di.sl<LeaveBloc>(),
        ),
        BlocProvider(
          create: (_) => di.sl<ProfileBloc>(),
        ),
        BlocProvider(
          create: (_) => di.sl<AnnouncementBloc>()..add(FetchAnnouncementsRequested()),
        ),
        BlocProvider(
          create: (_) => di.sl<NotificationBloc>()..add(FetchNotificationsRequested()),
        ),
        BlocProvider(
          create: (_) => di.sl<ShiftBloc>()..add(FetchSchedulesRequested(
            month: DateTime.now().month,
            year: DateTime.now().year,
          )),
        ),
        BlocProvider(
          create: (_) => di.sl<SyncBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'HRIS Wowin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
        routes: {
          '/sales_dashboard': (context) => const SalesDashboardPage(),
          '/delivery_dashboard': (context) => const DeliveryDashboardPage(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => 
          current is AuthError || (previous is Authenticated && current is Unauthenticated),
      listener: (context, state) {
        if (state is AuthError) {
          DialogUtils.showError(
            context: context,
            title: 'Gagal',
            message: state.message,
          );
        }
        
        if (state is Unauthenticated) {
          // Clear all routes above the base AuthWrapper when user logs out
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated || state is ChangePasswordSuccess) {
            return const HomePage();
          }
          
          if (state is Unauthenticated || 
              state is AuthError || 
              state is RegisterSuccess || 
              state is FaceRegistrationSuccess ||
              state is ForgotPasswordSuccess) {
            return const LoginPage(key: ValueKey('login_page'));
          }
          
          if (state is AuthInitial) {
            return const SplashScreen();
          }
  
          // Fallback for AuthLoading or other transient states
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }
}
