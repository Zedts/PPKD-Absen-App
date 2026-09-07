import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/providers/attendance_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/navigation_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/profile_provider.dart';
import 'core/services/dio_client.dart';
import 'core/services/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/main_shell.dart';

/// Root application widget configuring providers, theme, and routes.
class PpkdAbsenApp extends StatelessWidget {
  final SecureStorageService storageService;
  final DioClient dioClient;

  const PpkdAbsenApp({
    super.key,
    required this.storageService,
    required this.dioClient,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            storage: storageService,
            dioClient: dioClient,
          )..init(),
        ),
        ChangeNotifierProvider<AttendanceProvider>(
          create: (_) => AttendanceProvider(
            dioClient: dioClient,
          ),
        ),
        ChangeNotifierProvider<ProfileProvider>(
          create: (_) => ProfileProvider(
            dioClient: dioClient,
            storage: storageService,
          ),
        ),
        ChangeNotifierProvider<NavigationProvider>(
          create: (_) => NavigationProvider(),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider()..init(),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'PPKD Absen',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: auth.isLoggedIn ? const MainShell() : const WelcomeScreen(),
            routes: {
              WelcomeScreen.routeName: (_) => const WelcomeScreen(),
              SignInScreen.routeName: (_) => const SignInScreen(),
              RegisterScreen.routeName: (_) => const RegisterScreen(),
              ForgotPasswordScreen.routeName: (_) =>
                  const ForgotPasswordScreen(),
              ResetPasswordScreen.routeName: (_) =>
                  const ResetPasswordScreen(),
              MainShell.routeName: (_) => const MainShell(),
            },
          );
        },
      ),
    );
  }
}
