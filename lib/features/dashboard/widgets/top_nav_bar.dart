import 'package:flutter/material.dart';

class NavBar extends StatelessWidget implements PreferredSizeWidget {
  const NavBar({
    super.key,
    this.leading,
    this.onMenuPressed,
    this.username = "Persephone",
    this.showMenu = true,
    this.automaticallyImplyLeading = false,
  });

  final Widget? leading;
  final VoidCallback? onMenuPressed;
  final String username;
  final bool showMenu;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final Widget? computedLeading = showMenu
        ? IconButton(icon: const Icon(Icons.menu), onPressed: onMenuPressed)
        : null;
    return AppBar(
      toolbarHeight: 71,
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: false,
      title: const Image(
        image: AssetImage('assets/images/cameron_logo2.png'),
        height: 34,
      ),
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF111928),
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: Colors.grey.shade300,
          height: 2,
        ),
      ),
      leading: computedLeading,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 18.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {},
              ),
              const SizedBox(width: 10),
              const CircleAvatar(child: Icon(Icons.person, size: 20)),
              const SizedBox(width: 8),
              Text(
                username,
                style: const TextStyle(
                  color: Color(0xFF111928),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
