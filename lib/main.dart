import 'package:cu_plus_webapp/features/calender/ui/calendar_view.dart';
import 'package:cu_plus_webapp/features/manageStudents/ui/admin/manage_students_view.dart';
import 'package:cu_plus_webapp/features/announcements/ui/admin/announcements_view.dart';

import 'package:cu_plus_webapp/features/manageStudents/ui/admin/register_student_view.dart';
import 'package:cu_plus_webapp/features/manageStudents/ui/admin/student_detail_view.dart.dart';

import 'package:cu_plus_webapp/features/forms/ui/admin/create_form_view.dart';

import 'package:cu_plus_webapp/features/announcements/ui/student/announcements_view.dart';

import 'package:cu_plus_webapp/features/auth/ui/login_page.dart';

import 'package:cu_plus_webapp/features/dashboard/ui/dashboard_shell.dart';
import 'package:cu_plus_webapp/features/courseContent/ui/course_content_view.dart';

import 'package:cu_plus_webapp/features/forms/ui/student/student_form_fill_view.dart';
import 'package:cu_plus_webapp/features/forms/ui/admin/admin_form_preview_view.dart';
import 'package:cu_plus_webapp/features/forms/ui/admin/admin_form_submissions_view.dart';
import 'package:cu_plus_webapp/features/forms/ui/admin/admin_form_submission_detail_view.dart';
import 'package:cu_plus_webapp/features/support/ui/support_view.dart';
import 'package:cu_plus_webapp/features/setting/ui/setting_view.dart';

import 'package:flutter/material.dart';
import 'features/auth/ui/first_page.dart';

import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';
import 'package:cu_plus_webapp/core/network/api_client.dart';
import 'package:cu_plus_webapp/features/auth/controller/auth_controller.dart';
import 'package:cu_plus_webapp/features/auth/api/auth_api.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => ApiClient()),
        ProxyProvider<ApiClient, AuthApi>(
          update: (_, client, __) => AuthApi(client),
        ),
        ChangeNotifierProxyProvider<AuthApi, AuthController>(
          create: (context) => AuthController(context.read<AuthApi>()),
          update: (_, authApi, authController) =>
              authController ?? AuthController(authApi),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
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
          return DashboardShell(child: child);
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
            path: '/dashboard/calendar',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                key: state.pageKey,
                child: CalendarView(),
              );
            },
          ),
          GoRoute(
            path: '/dashboard/admin/announcements',
            pageBuilder: (context, state) {
              final email = auth.user?.email ?? '';
              return NoTransitionPage(
                key: state.pageKey,
                child: AdminAnnoucementsView(email: email),
              );
            },
          ),
          GoRoute(
            path: '/dashboard/student/announcements',
            pageBuilder: (context, state) {
              final email = auth.user?.email ?? '';
              return NoTransitionPage(
                key: state.pageKey,
                child: StudentAnnouncementsView(email: email),
              );
            },
          ),
          GoRoute(
            path: '/dashboard/admin/forms',
            pageBuilder: (context, state) {
              final email = auth.user?.email ?? '';
              return NoTransitionPage(
                key: state.pageKey,
                child: CourseContentView(email: email),
              );
            },
          ),
          GoRoute(
            path: '/dashboard/admin/forms/create',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                key: state.pageKey,
                child: const CreateFormView(),
              );
            },
          ),
          GoRoute(
            path: '/dashboard/admin/forms/:id/edit',
            pageBuilder: (context, state) {
              final formId = state.pathParameters['id']!;
              return NoTransitionPage(
                key: state.pageKey,
                child: CreateFormView(formId: formId),
              );
            },
          ),
          GoRoute(
            path: '/dashboard/admin/forms/:id/preview',
            pageBuilder: (context, state) {
              final formId = state.pathParameters['id']!;
              return NoTransitionPage(
                key: state.pageKey,
                child: AdminFormPreviewView(formId: formId),
              );
            },
          ),
          GoRoute(
            path: '/dashboard/admin/forms/:id/submissions',
            pageBuilder: (context, state) {
              final formId = state.pathParameters['id']!;
              return NoTransitionPage(
                key: state.pageKey,
                child: AdminFormSubmissionsView(formId: formId),
              );
            },
          ),
          GoRoute(
            path: '/dashboard/admin/forms/submissions/:submissionId/detail',
            pageBuilder: (context, state) {
              final submissionId = state.pathParameters['submissionId']!;
              return NoTransitionPage(
                key: state.pageKey,
                child: AdminFormSubmissionDetailView(
                  submissionId: submissionId,
                ),
              );
            },
          ),
          GoRoute(
            path: '/dashboard/student/forms/:id',
            pageBuilder: (context, state) {
              final formId = state.pathParameters['id']!;
              return NoTransitionPage(
                key: state.pageKey,
                child: StudentFormFillView(formId: formId),
              );
            },
          ),
          GoRoute(
            path: '/dashboard/support',
            pageBuilder: (context, state) {
              return NoTransitionPage(key: state.pageKey, child: SupportView());
            },
          ),
          GoRoute(
            path: '/dashboard/setting',
            pageBuilder: (context, state) {
              return NoTransitionPage(key: state.pageKey, child: SettingView());
            },
          ),
          GoRoute(
            path: '/dashboard/admin/students/:id',
            builder: (context, state) {
              final studentId = state.pathParameters['id']!;
              final mode = state.uri.queryParameters['mode'];

              return StudentDetailView(
                studentId: studentId,
                startInEditMode: mode == 'edit',
              );
            },
          ),
        ],
      ),
    ],
  );

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GoRouter? _router;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthController>().loadSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    _router ??= MyApp._createRouter(auth);

    if (auth.isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp.router(
      routerConfig: _router!,

      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        fontFamily: 'DMSans',

        scaffoldBackgroundColor: Colors.white,
      ),
    );
  }
}
