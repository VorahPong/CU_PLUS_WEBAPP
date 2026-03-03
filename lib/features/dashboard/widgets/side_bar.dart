import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum SidebarItem { courseContent, message, calendar, manageStudents, support, setting }

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.selectedItem,
    required this.onSelect,
    required this.onLogout,
  });

  final SidebarItem selectedItem;
  final void Function(SidebarItem item) onSelect;
  final VoidCallback onLogout;

Widget _item({
  required BuildContext context,
  required SidebarItem item,
  required String title,
  required String iconPath,
  double iconSize = 22,
  void Function()? onTap, 
}) {
  final isActive = selectedItem == item;

  return StatefulBuilder(
    builder: (context, setLocalState) {
      bool isHover = false;

      return MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setLocalState(() => isHover = true),
        onExit: (_) => setLocalState(() => isHover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          padding: const EdgeInsets.symmetric(vertical: 4),
          transform: Matrix4.identity(),
          decoration: BoxDecoration(
            color: (isActive || isHover) ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: (isActive || isHover)
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: SizedBox(
              width: 28,
              height: 28,
              child: Center(
                child: SvgPicture.asset(
                  iconPath,
                  width: iconSize,
                  height: iconSize,
                ),
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            onTap: onTap ?? () => onSelect(item),
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      color: const Color(0xFFFFD971),
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        children: [
          _item(
            context: context,
            item: SidebarItem.courseContent,
            title: "Course Content",
            iconPath: 'assets/images/side-bar/book-icon.svg',
            iconSize: 20,
          ),
          _item(
            context: context,
            item: SidebarItem.message,
            title: "Message",
            iconPath: 'assets/images/side-bar/message-icon.svg',
            iconSize: 22,
          ),
          _item(
            context: context,
            item: SidebarItem.calendar,
            title: "Calendar",
            iconPath: 'assets/images/side-bar/calender-icon.svg',
            iconSize: 28,
          ),
          _item(
            context: context,
            item: SidebarItem.manageStudents,
            title: "Manage Students",
            iconPath: 'assets/images/side-bar/student-icon.svg',
            iconSize: 28,
          ),

          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: Color(0xFF99C199), thickness:1),
          ),

          _item(
            context: context,
            item: SidebarItem.support,
            title: "Support",
            iconPath: 'assets/images/side-bar/support-icon.svg',
            iconSize: 26,
          ),
          _item(
            context: context,
            item: SidebarItem.setting,
            title: "Setting",
            iconPath: 'assets/images/side-bar/setting-icon.svg',
            iconSize: 26,
          ),

          // Logout button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFFFFBD5D5),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: SvgPicture.asset(
                  'assets/images/side-bar/logout-icon.svg',
                  width: 20,
                  height: 20,
                ),
                title: const Text(
                  "Log out",
                  style: TextStyle(color: Color(0xFF9B1C1C)),
                ),
                onTap: onLogout,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
