import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/side_bar.dart';
import '../widgets/top_nav_bar.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key, required this.email, required this.child});

  final String email;
  final Widget child;
  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  bool _showSidebar = false;
  late SidebarItem _selectedItem;

  @override
  void initState() {
    super.initState();
    _selectedItem = SidebarItem.courseContent;
  }

  void _selectItem(SidebarItem item, {required bool isDesktop}) {
    setState(() {
      _selectedItem = item;
      if (!isDesktop) _showSidebar = false;
    });

    // ✅ route based on item
    switch (item) {
      case SidebarItem.courseContent:
        context.go('/dashboard'); // or /dashboard/course-content
        break;
      case SidebarItem.message:
        context.go('/dashboard/message');
        break;
      case SidebarItem.calendar:
        context.go('/dashboard/calendar');
        break;
      case SidebarItem.manageStudents:
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
          routeItem = SidebarItem.manageStudents;
        } else if (loc.startsWith('/dashboard/message')) {
          routeItem = SidebarItem.message;
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
            username: widget.email,
            //\automaticallyImplyLeading: false,
          ),
          body: isDesktop
              ? Row(
                  children: [
                    SizedBox(
                      width: 262,
                      child: Sidebar(
                        selectedItem: _selectedItem,
                        onSelect: (item) => _selectItem(item, isDesktop: true),
                        onLogout: () {
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
                              onSelect: (item) =>
                                  _selectItem(item, isDesktop: false),
                              onLogout: () {
                                setState(() => _showSidebar = false);
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
