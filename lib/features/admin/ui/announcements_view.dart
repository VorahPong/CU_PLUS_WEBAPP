import 'package:cu_plus_webapp/core/network/api_client.dart';
import 'package:cu_plus_webapp/features/admin/api/announcement_api.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'create_announcement_page.dart';
import 'package:cu_plus_webapp/features/admin/widgets/announcement_feed.dart';

class AdminAnnoucementsView extends StatefulWidget {
  const AdminAnnoucementsView({
    super.key,
    required this.email,
  });

  final String email;

  @override
  State<AdminAnnoucementsView> createState() => _AdminAnnoucementsViewState();
}

class _AdminAnnoucementsViewState extends State<AdminAnnoucementsView> {
  List<dynamic> _announcements = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnnouncements();
    });
  }

  Future<void> _loadAnnouncements() async {
    try {
      final client = context.read<ApiClient>();
      final api = AnnouncementApi(client);

      final data = await api.getAnnouncements();

      if (!mounted) return;

      setState(() {
        _announcements = data;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst("Exception: ", "");
        _loading = false;
      });
    }
  }

  Future<void> _createPost() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateAnnouncementPage(),
      ),
    );

    if (created == true) {
      await _loadAnnouncements();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Announcement created")),
      );
    }
  }

  Future<void> _editPost(int index) async {
  final announcement = Map<String, dynamic>.from(_announcements[index]);

  final updated = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (context) => CreateAnnouncementPage(
        announcement: announcement,
      ),
    ),
  );

  if (updated == true) {
    await _loadAnnouncements();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Announcement updated")),
    );
  }
}

  Future<void> _deletePost(int index) async {
    final announcement = _announcements[index];
    final id = announcement['id'];

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Announcement ID missing")),
      );
      return;
    }

    try {
      final client = context.read<ApiClient>();
      final api = AnnouncementApi(client);

      await api.deleteAnnouncement(id);

      if (!mounted) return;

      await _loadAnnouncements();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Announcement deleted")),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst("Exception: ", ""),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: Text(
              "Announcement",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade300, thickness: 1),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Logged in as: ${widget.email}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: AnnouncementFeed(
                      announcements: _announcements,
                      loading: _loading,
                      error: _error,
                      onRetry: _loadAnnouncements,
                      onEdit: _editPost,
                      onDelete: _deletePost,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: OutlinedButton.icon(
                      onPressed: _createPost,
                      icon: const Icon(
                        Icons.add_circle_outline,
                        size: 18,
                      ),
                      label: const Text("Create new post"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey.shade300),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}