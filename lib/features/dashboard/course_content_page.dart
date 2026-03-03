import 'package:flutter/material.dart';
import './components/side_bar.dart';
import 'package:cu_plus_webapp/features/dashboard/components/top_nav_bar.dart';

class CourseContentPage extends StatefulWidget {
  const CourseContentPage({super.key, required this.email});
  final String email;

  @override
  State<CourseContentPage> createState() => _CourseContentState();
}

class _CourseContentState extends State<CourseContentPage> {
  bool _showSidebar = false;
  SidebarItem _selectedItem = SidebarItem.course;

  void _selectItem(SidebarItem item, {required bool isDesktop}) {
    setState(() {
      _selectedItem = item;
      if (!isDesktop) _showSidebar = false; // close drawer on mobile
    });

    // TODO: navigate based on item
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        // If we switch to desktop while sidebar was open on mobile, close it
        if (isDesktop && _showSidebar) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _showSidebar = false);
          });
        }

        final pageContent = Center(
          child: Text("Logged in as: ${widget.email}"),
        );

        return Scaffold(
          appBar: NavBar(
            showMenu: !isDesktop,
            onMenuPressed: () => setState(() => _showSidebar = !_showSidebar),
            username: widget.email,
            //\automaticallyImplyLeading: false,
          ),
          body: isDesktop
              // Desktop layout: sidebar always visible
              ? Row(
                  children: [
                    SizedBox(
                      width: 262,
                      child: Sidebar(
                        selectedItem: _selectedItem,
                        onSelect: (item) => _selectItem(item, isDesktop: true),
                        onLogout: () {
                          // TODO: clear token + navigate to login
                        },
                      ),
                    ),
                    const VerticalDivider(width: 0, thickness: 0),
                    Expanded(child: pageContent),
                  ],
                )
              // Mobile layout: overlay drawer
              : Stack(
                  children: [
                    // Main content
                    Center(child: Text("Logged in as: ${widget.email}")),

                    // Backdrop (tap to close)
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

                    // Sliding sidebar
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
                              onSelect: (item) {
                                setState(() {
                                  _selectedItem = item;
                                  _showSidebar = false;
                                });
                              },
                              onLogout: () {
                                setState(() => _showSidebar = false);
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
