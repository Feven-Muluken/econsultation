import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import '../../features/splash/screens/splash_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/home_screen.dart';
// import 'secure_storage.dart'; // helper for token storage

class AppRouter {
  static final GoRouter router = GoRouter(
    routes: [
      // GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/otp', builder: (context, state) => const OtpScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    ],
    // redirect: (context, state) {
      // final token = SecureStorage.readToken();
      // final isAuth = token != null;

      // if (!isAuth && state.location == '/home') {
      //   return '/welcome';
      // }
      // if (isAuth && (state.location == '/login' || state.location == '/register')) {
      //   return '/home';
      // }
      // return null;
    // },
  );
}
