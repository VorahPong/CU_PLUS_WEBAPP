import 'package:cu_plus_webapp/features/auth/ui/login_page.dart';
import 'package:cu_plus_webapp/features/dashboard/ui/dashboard_shell.dart';
import 'package:flutter/material.dart';
import 'features/auth/ui/first_page.dart';
import 'package:go_router/go_router.dart';
void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Define router here
  static final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => FirstPage(),
      ),
      GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) {
          return const DashboardShell(email: '');
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'DMSans',
        scaffoldBackgroundColor: Colors.white,
      ),
    );
  }
}
