import 'package:cu_plus_webapp/features/admin/ui/calender_view.dart';
import 'package:cu_plus_webapp/features/admin/ui/manage_students_view.dart';
import 'package:cu_plus_webapp/features/admin/ui/message_view.dart';
import 'package:cu_plus_webapp/features/admin/ui/register_student_view.dart';
import 'package:cu_plus_webapp/features/auth/ui/login_page.dart';
import 'package:cu_plus_webapp/features/dashboard/ui/dashboard_shell.dart';
import 'package:cu_plus_webapp/features/admin/ui/course_content_view.dart';
import 'package:flutter/material.dart';
import 'features/auth/ui/first_page.dart';

import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';
import 'features/auth/controller/auth_controller.dart';
import 'package:cu_plus_webapp/core/network/api_client.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>(
          create: (_) => ApiClient(),
        ),
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Define router here
  static GoRouter _createRouter(AuthController auth) => GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = auth.isLoggedIn;
      final isAdmin = auth.isAdmin;
      final location = state.matchedLocation;

      final goingToLogin = location == '/login';
      final goingToLanding = location == '/';
      final goingToDashboard = location.startsWith('/dashboard');
      final goingToAdminRoute = location.startsWith('/dashboard/admin');

      if (auth.isLoading) return null;

      if (!loggedIn) {
        if (goingToDashboard) return '/login';
        return null;
      }

      if (loggedIn && (goingToLogin || goingToLanding)) {
        return '/dashboard';
      }

      if (goingToAdminRoute && !isAdmin) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: FirstPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          );
        },
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const LoginPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          return DashboardShell(
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) {
              final email = auth.user?.email ?? '';
              return NoTransitionPage(
                key: state.pageKey,
                child: CourseContentView(email: email),
              );
            },
          ),
          GoRoute(
            path: '/dashboard/admin/students',
            pageBuilder: (context, state) {
              final email = auth.user?.email ?? '';
              return NoTransitionPage(
                key: state.pageKey,
                child: ManageStudentsView(email: email),
              );
            },
          ),
          GoRoute(
            path: '/dashboard/admin/students/register',
            pageBuilder: (context, state) {
              final email = auth.user?.email ?? '';
              return NoTransitionPage(
                key: state.pageKey,
                child: RegisterStudentView(email: email),
              );
            },
          ),
          GoRoute(
            path: '/dashboard/admin/calendar',
            pageBuilder: (context, state) {
              final email = auth.user?.email ?? '';
              return NoTransitionPage(
                key: state.pageKey,
                child: CalenderView(email: email),
              );
            },
          ),
          GoRoute(
            path: '/dashboard/message',
            pageBuilder: (context, state) {
              final email = auth.user?.email ?? '';
              return NoTransitionPage(
                key: state.pageKey,
                child: MessageView(email: email),
              );
            },
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {

    final auth = context.watch<AuthController>();
    final router = _createRouter(auth);
    
    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'DMSans',
        scaffoldBackgroundColor: Colors.white,
      ),
    );
  }
}
