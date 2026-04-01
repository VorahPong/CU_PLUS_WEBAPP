import 'package:cu_plus_webapp/core/network/api_client.dart';
import 'package:cu_plus_webapp/features/admin/api/announcement_api.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'create_announcement_page.dart';

class AnnoucementsView extends StatefulWidget {
  const AnnoucementsView({
    super.key,
    required this.email,
  });

  final String email;

  @override
  State<AnnoucementsView> createState() => _AnnoucementsViewState();
}

class _AnnoucementsViewState extends State<AnnoucementsView> {
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

  String _buildAudienceText(dynamic announcement) {
    if (announcement['everyone'] == true) {
      return "To: everyone";
    }

    final List<String> years = [];

    if (announcement['firstYear'] == true) years.add("first-year");
    if (announcement['secondYear'] == true) years.add("second-year");
    if (announcement['thirdYear'] == true) years.add("third-year");
    if (announcement['fourthYear'] == true) years.add("fourth-year");

    if (years.isEmpty) {
      return "To: no group selected";
    }

    return "To: ${years.join(', ')}";
  }

  String _formatDate(dynamic rawDate) {
    if (rawDate == null) return "";

    final parsed = DateTime.tryParse(rawDate.toString());
    if (parsed == null) return rawDate.toString();

    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];

    return "${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}";
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
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                            ? Center(child: Text(_error!))
                            : _announcements.isEmpty
                                ? Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        "No announcements yet",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: _announcements.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 18),
                                    itemBuilder: (context, index) {
                                      final announcement =
                                          _announcements[index];
                                      final author =
                                          announcement['author'] ?? {};

                                      final firstName =
                                          author['firstName'] ?? "";
                                      final lastName =
                                          author['lastName'] ?? "";

                                      return _AnnouncementCard(
                                        author:
                                            "$firstName $lastName".trim(),
                                        date: _formatDate(
                                          announcement['createdAt'],
                                        ),
                                        audience:
                                            _buildAudienceText(announcement),
                                        message:
                                            announcement['message'] ?? "",
                                        onEdit: () => _editPost(index),
                                        onDelete: () => _deletePost(index),
                                      );
                                    },
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

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.author,
    required this.date,
    required this.audience,
    required this.message,
    required this.onEdit,
    required this.onDelete,
  });

  final String author;
  final String date;
  final String audience;
  final String message;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.10),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.orange.shade100,
            child: const Icon(
              Icons.person,
              size: 18,
              color: Colors.deepOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      author.isEmpty ? "Unknown author" : author,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "$date ($audience)",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}