import 'package:go_router/go_router.dart';
// import '../../features/splash/screens/splash_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/register_success_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/document_details_screen.dart';
import '../../features/home/screens/feedback_screen.dart';
import '../../features/home/screens/news_detail_screen.dart';
import '../../features/home/screens/news_screen.dart';
import '../../features/home/screens/my_account_screen.dart';
import '../../features/home/screens/settings_screen.dart';
import '../../features/regulations/screens/regulations_screen.dart';
// import 'secure_storage.dart'; // helper for token storage

class AppRouter {
  static final GoRouter router = GoRouter(
    routes: [
      // GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(
        path: '/register-success',
        builder: (context, state) => const RegisterSuccessScreen(),
      ),
      GoRoute(path: '/otp', builder: (context, state) => const OtpScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/news', builder: (context, state) => const NewsScreen()),
      GoRoute(
        path: '/news/:id',
        builder: (context, state) => NewsDetailScreen(
          newsId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/documents',
        builder: (context, state) {
          final query = state.uri.queryParameters['q'];
          return RegulationsScreen(initialQuery: query);
        },
      ),
      GoRoute(
        path: '/documents/:id',
        builder: (context, state) => RegulationDetailScreen(
          regulationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/feedback',
        builder: (context, state) => const FeedbackScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/my-account',
        builder: (context, state) => const MyAccountScreen(),
      ),
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
