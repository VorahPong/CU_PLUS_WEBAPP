import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cu_plus_webapp/core/network/api_client.dart';
import 'package:cu_plus_webapp/features/announcements/api/announcement_api.dart';
import 'package:cu_plus_webapp/features/announcements/widgets/announcement_feed.dart';
class StudentAnnouncementsView extends StatefulWidget {
  const StudentAnnouncementsView({
    super.key,
    required this.email,
  });

  final String email;

  @override
  State<StudentAnnouncementsView> createState() =>
      _StudentAnnouncementsViewState();
}

class _StudentAnnouncementsViewState extends State<StudentAnnouncementsView> {
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

      final data = await api.getStudentAnnouncements();

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
              "Announcements",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade300, thickness: 1),
          const SizedBox(height: 20),
          Expanded(
            child: AnnouncementFeed(
              announcements: _announcements,
              loading: _loading,
              error: _error,
              onRetry: _loadAnnouncements,
            ),
          ),
        ],
      ),
    );
  }
}