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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
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
      ],
      child: MaterialApp(
        title: 'HRIS Wowin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          return const HomePage();
        } else if (state is Unauthenticated || state is AuthError || state is RegisterSuccess) {
          return const LoginPage();
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
