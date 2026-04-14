import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/side_bar.dart';
import '../widgets/top_nav_bar.dart';
import '../api/notifications_api.dart';
import '../../setting/api/settings_api.dart';
import '../../../core/network/api_client.dart';
import '../../../core/extensions/auth_extension.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key, required this.child});

  final Widget child;
  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  bool _showSidebar = false;
  late SidebarItem _selectedItem;
  int _unreadNotificationCount = 0;
  List<Map<String, dynamic>> _notifications = [];
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _selectedItem = SidebarItem.courseContent;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
      _loadCurrentUser();
    });
  }

  Future<void> _loadNotifications() async {
    try {
      final api = NotificationsApi(context.read<ApiClient>());
      final notifications = await api.getNotifications();
      final count = await api.getUnreadCount();

      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _unreadNotificationCount = count;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notifications = [];
        _unreadNotificationCount = 0;
      });
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final api = SettingsApi(context.read<ApiClient>());
      final user = await api.getProfile();

      if (!mounted) return;
      setState(() {
        _currentUser = user;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _currentUser = null;
      });
    }
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> notification) async {
    final id = notification['id']?.toString();
    final targetType = notification['targetType']?.toString();
    final targetId = notification['targetId']?.toString();
    final isRead = notification['isRead'] == true;

    try {
      final api = NotificationsApi(context.read<ApiClient>());

      if (!isRead && id != null) {
        await api.markAsRead(id);
      }

      await _loadNotifications();

      if (!mounted) return;

      if (targetType == 'form' && targetId != null) {
        context.go('/dashboard/student/forms/$targetId');
        return;
      }

      if (targetType == 'announcement') {
        context.go('/dashboard/student/announcements');
        return;
      }
    } catch (_) {
      if (!mounted) return;
    }
  }

  Future<void> _handleDeleteNotification(String id) async {
    try {
      final api = NotificationsApi(context.read<ApiClient>());
      await api.deleteNotification(id);
      await _loadNotifications();
    } catch (_) {}
  }

  Future<void> _handleClearAllNotifications() async {
    try {
      final api = NotificationsApi(context.read<ApiClient>());
      await api.clearAllNotifications();
      await _loadNotifications();
    } catch (_) {}
  }

  void _selectItem(SidebarItem item, {required bool isDesktop}) {
    setState(() {
      _selectedItem = item;
      if (!isDesktop) _showSidebar = false;
    });

    // route based on item
    switch (item) {
      case SidebarItem.courseContent:
        context.go('/dashboard');
        break;
      case SidebarItem.announcements:
        context.go('/dashboard/student/announcements');
        break;
      case SidebarItem.adminAnnouncements:
        context.go('/dashboard/admin/announcements');
        break;
      case SidebarItem.calendar:
        context.go('/dashboard/calendar');
        break;
      case SidebarItem.adminManageStudents:
        context.go('/dashboard/admin/students');
        break;
      case SidebarItem.support:
        context.go('/dashboard/support');
        break;
      case SidebarItem.setting:
        context.go('/dashboard/setting');
        break;
    }
  }

  int _indexFor(SidebarItem item) => SidebarItem.values.indexOf(item);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final auth = context.auth;
        final isAdmin = auth.isAdmin;
        final email = auth.user?.email ?? "";

        final isDesktop = constraints.maxWidth >= 900;

        if (isDesktop && _showSidebar) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _showSidebar = false);
          });
        }

        final content = widget.child;

        final loc = GoRouterState.of(context).uri.toString();

        final SidebarItem routeItem;
        if (loc.startsWith('/dashboard/admin/students')) {
          routeItem = SidebarItem.adminManageStudents;
        } else if (loc.startsWith('/dashboard/admin/announcements')) {
          routeItem = SidebarItem.adminAnnouncements;
        } else if (loc.startsWith('/dashboard/student/announcements')) {
          routeItem = SidebarItem.announcements;
        } else if (loc.startsWith('/dashboard/calendar')) {
          routeItem = SidebarItem.calendar;
        } else if (loc.startsWith('/dashboard/support')) {
          routeItem = SidebarItem.support;
        } else if (loc.startsWith('/dashboard/setting')) {
          routeItem = SidebarItem.setting;
        } else {
          routeItem = SidebarItem.courseContent;
        }

        // keep UI in sync with URL (without setState)
        _selectedItem = routeItem;

        return Scaffold(
          appBar: NavBar(
            showMenu: !isDesktop,
            onMenuPressed: () => setState(() => _showSidebar = !_showSidebar),
            unreadNotificationCount: _unreadNotificationCount,
            notifications: _notifications,
            onNotificationTap: _handleNotificationTap,
            onDeleteNotification: _handleDeleteNotification,
            onClearAllNotifications: _handleClearAllNotifications,
            username: email,
            profileImageUrl: _currentUser?['profileImageUrl']?.toString(),
            //\automaticallyImplyLeading: false,
          ),
          body: isDesktop
              ? Row(
                  children: [
                    SizedBox(
                      width: 262,
                      child: Sidebar(
                        selectedItem: _selectedItem,
                        isAdmin: isAdmin,
                        onSelect: (item) => _selectItem(item, isDesktop: true),
                        onLogout: () async {
                          await context.authRead.logout();
                          if (!mounted) return;
                          context.go('/login');
                        },
                      ),
                    ),
                    Expanded(child: content),
                  ],
                )
              : Stack(
                  children: [
                    Positioned.fill(child: content),

                    IgnorePointer(
                      ignoring: !_showSidebar,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _showSidebar ? 1 : 0,
                        child: GestureDetector(
                          onTap: () => setState(() => _showSidebar = false),
                          child: Container(
                            color: Colors.black.withOpacity(0.35),
                          ),
                        ),
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        offset: _showSidebar
                            ? Offset.zero
                            : const Offset(-1, 0),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: _showSidebar ? 1 : 0,
                          child: SizedBox(
                            width: double.infinity,
                            child: Sidebar(
                              selectedItem: _selectedItem,
                              isAdmin: isAdmin,
                              onSelect: (item) =>
                                  _selectItem(item, isDesktop: false),
                              onLogout: () async {
                                await context.authRead.logout();
                                if (!mounted) return;
                                context.go('/login');
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
