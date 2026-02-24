import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/firebase_config.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/common/splash_screen.dart';
import 'screens/professor/prof_dashboard.dart';
import 'screens/student/student_dashboard.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(const QuizMasterApp());
}

class QuizMasterApp extends StatelessWidget {
  const QuizMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        title: 'Quiz Master',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const SplashScreen(),
        routes: {
          AppConstants.routeSplash: (context) => const SplashScreen(),
          AppConstants.routeLogin: (context) => const LoginScreen(),
          AppConstants.routeSignup: (context) => const SignupScreen(),
          AppConstants.routeProfessorDashboard: (context) =>
              const ProfessorDashboard(),
          AppConstants.routeStudentDashboard: (context) =>
              const StudentDashboard(),
        },
      ),
    );
  }
}
