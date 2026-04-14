import 'package:flutter/material.dart';

class NavBar extends StatelessWidget implements PreferredSizeWidget {
  const NavBar({
    super.key,
    this.leading,
    this.onMenuPressed,
    this.username = "Persephone",
    this.profileImageUrl,
    this.showMenu = true,
    this.automaticallyImplyLeading = false,
    this.onNotificationsPressed,
    this.unreadNotificationCount = 0,
    this.notifications = const [],
    this.onNotificationTap,
    this.onDeleteNotification,
    this.onClearAllNotifications,
  });

  final Widget? leading;
  final VoidCallback? onMenuPressed;
  final String username;
  final String? profileImageUrl;
  final bool showMenu;
  final bool automaticallyImplyLeading;
  final VoidCallback? onNotificationsPressed;
  final int unreadNotificationCount;
  final List<Map<String, dynamic>> notifications;
  final Future<void> Function(Map<String, dynamic> notification)? onNotificationTap;
  final Future<void> Function(String notificationId)? onDeleteNotification;
  final Future<void> Function()? onClearAllNotifications;
  String _formatNotificationTime(dynamic rawDate) {
    if (rawDate == null) return '';

    final parsed = DateTime.tryParse(rawDate.toString());
    if (parsed == null) return '';

    final now = DateTime.now();
    final difference = now.difference(parsed);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${parsed.month}/${parsed.day}/${parsed.year}';
  }

  Future<void> _showNotificationsPanel(BuildContext context) async {
    await showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (dialogContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(dialogContext).pop(),
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              top: 60,
              right: 24,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 360,
                  constraints: const BoxConstraints(maxHeight: 500),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Notifications',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (onClearAllNotifications != null && notifications.isNotEmpty)
                              TextButton(
                                onPressed: () async {
                                  await onClearAllNotifications!();
                                  if (dialogContext.mounted) {
                                    Navigator.of(dialogContext).pop();
                                  }
                                },
                                child: const Text('Clear'),
                              ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: Colors.grey.shade300),
                      if (notifications.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'No notifications yet',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: notifications.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: Colors.grey.shade200,
                            ),
                            itemBuilder: (context, index) {
                              final notification = notifications[index];
                              final id = notification['id']?.toString();
                              final isRead = notification['isRead'] == true;
                              final title =
                                  (notification['title'] ?? 'Notification').toString();
                              final message =
                                  (notification['message'] ?? '').toString();
                              final timeText = _formatNotificationTime(
                                notification['createdAt'],
                              );

                              return InkWell(
                                onTap: () async {
                                  if (onNotificationTap != null) {
                                    await onNotificationTap!(notification);
                                  }
                                  if (dialogContext.mounted) {
                                    Navigator.of(dialogContext).pop();
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 3),
                                        child: Icon(
                                          isRead
                                              ? Icons.check_circle
                                              : Icons.notifications_active,
                                          color: isRead ? Colors.grey : Colors.green,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    title,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: isRead
                                                          ? FontWeight.w600
                                                          : FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                if (timeText.isNotEmpty)
                                                  Text(
                                                    timeText,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            if (message.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                message,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (id != null && onDeleteNotification != null)
                                        IconButton(
                                          tooltip: 'Dismiss notification',
                                          onPressed: () async {
                                            await onDeleteNotification!(id);
                                            if (dialogContext.mounted) {
                                              Navigator.of(dialogContext).pop();
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.close,
                                            size: 18,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final Widget? computedLeading = showMenu
        ? IconButton(icon: const Icon(Icons.menu), onPressed: onMenuPressed)
        : null;
    final int safeUnreadCount = unreadNotificationCount < 0 ? 0 : unreadNotificationCount;
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () async {
                      if (onNotificationsPressed != null) {
                        onNotificationsPressed!();
                        return;
                      }
                      await _showNotificationsPanel(context);
                    },
                    tooltip: 'Notifications',
                  ),
                  if (safeUnreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          safeUnreadCount > 99 ? '99+' : safeUnreadCount.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                backgroundImage: profileImageUrl != null &&
                        profileImageUrl!.trim().isNotEmpty
                    ? NetworkImage(profileImageUrl!.trim())
                    : null,
                child: profileImageUrl == null ||
                        profileImageUrl!.trim().isEmpty
                    ? const Icon(Icons.person, size: 20)
                    : null,
              ),
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
