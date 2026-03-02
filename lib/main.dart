import 'package:cu_plus_webapp/features/admin/ui/manage_students_view.dart';
import 'package:cu_plus_webapp/features/admin/ui/register_student_view.dart';
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
      GoRoute(path: '/', builder: (context, state) => FirstPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      // Everything under /dashboard keeps sidebar
      ShellRoute(
        builder: (context, state, child) {
          // You can read email from query param later
          final email = state.uri.queryParameters['email'] ?? '';
          return DashboardShell(
            email: email,
            child: child, // ✅ center content
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) =>
                const SizedBox(), // default content (optional)
          ),
          GoRoute(
            path: '/dashboard/admin/students',
            builder: (context, state) {
              final email = state.uri.queryParameters['email'] ?? '';
              return ManageStudentsView(email: email);
            },
          ),
          GoRoute(
            path: '/dashboard/admin/students/register',
            builder: (context, state) {
              final email = state.uri.queryParameters['email'] ?? '';
              return RegisterStudentView(email: email);
            },
          ),
        ],
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
