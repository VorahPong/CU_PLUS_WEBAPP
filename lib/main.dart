import 'package:cu_plus_webapp/features/admin/ui/manage_students_view.dart';
import 'package:cu_plus_webapp/features/admin/ui/register_student_view.dart';
import 'package:cu_plus_webapp/features/auth/ui/login_page.dart';
import 'package:cu_plus_webapp/features/dashboard/ui/dashboard_shell.dart';
import 'package:cu_plus_webapp/features/students/ui/course_content_view.dart';
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
        pageBuilder: (context, state) {
          return CustomTransitionPage(key: state.pageKey, child: FirstPage(), transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          });
        },
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) {
          return CustomTransitionPage(key: state.pageKey, child: const LoginPage(), transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          });
        },
      ),
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
            pageBuilder: (context, state) {
              final email = state.uri.queryParameters['email'] ?? '';
              return NoTransitionPage(
                key: state.pageKey,
                child: CourseContentView(email: email),
              );
            },
          ),
          GoRoute(
            path: '/dashboard/admin/students',
            pageBuilder: (context, state) {
              final email = state.uri.queryParameters['email'] ?? '';
              return NoTransitionPage(
                key: state.pageKey,
                child: ManageStudentsView(email: email),
              );
            },
          ),
          GoRoute(
            path: '/dashboard/admin/students/register',
            pageBuilder: (context, state) {
              final email = state.uri.queryParameters['email'] ?? '';
              return NoTransitionPage(
                key: state.pageKey,
                child: RegisterStudentView(email: email),
              );
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
