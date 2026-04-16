import 'package:flutter/material.dart';

class AnnouncementFeed extends StatelessWidget {
  const AnnouncementFeed({
    super.key,
    required this.announcements,
    required this.loading,
    required this.error,
    required this.onRetry,
    this.onEdit,
    this.onDelete,
    this.emptyText = "No announcements yet",
  });

  final List<dynamic> announcements;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final void Function(int index)? onEdit;
  final void Function(int index)? onDelete;
  final String emptyText;

  String _buildAudienceText(dynamic announcement) {
    if (announcement['everyone'] == true) {
      return "To: everyone";
    }

    final years = <String>[];
    if (announcement['firstYear'] == true) years.add("first-year");
    if (announcement['secondYear'] == true) years.add("second-year");
    if (announcement['thirdYear'] == true) years.add("third-year");
    if (announcement['fourthYear'] == true) years.add("fourth-year");

    if (years.isEmpty) return "To: no group selected";
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

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text("Retry")),
          ],
        ),
      );
    }

    if (announcements.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Text(emptyText, style: const TextStyle(fontSize: 16)),
        ),
      );
    }

    return ListView.separated(
      itemCount: announcements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (context, index) {
        final announcement = announcements[index];
        final author = announcement['author'] ?? {};
        final firstName = author['firstName'] ?? "";
        final lastName = author['lastName'] ?? "";

        return _AnnouncementCard(
          author: "$firstName $lastName".trim(),
          date: _formatDate(announcement['createdAt']),
          audience: _buildAudienceText(announcement),
          message: announcement['message'] ?? "",
          status: (announcement['status'] ?? 'published').toString(),
          onEdit: onEdit != null ? () => onEdit!(index) : null,
          onDelete: onDelete != null ? () => onDelete!(index) : null,
        );
      },
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.author,
    required this.date,
    required this.audience,
    required this.message,
    required this.status,
    this.onEdit,
    this.onDelete,
  });

  final String author;
  final String date;
  final String audience;
  final String message;
  final String status;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final showActions = onEdit != null || onDelete != null;
    final isDraft = status.toLowerCase() == 'draft';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
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
            child: const Icon(Icons.person, size: 18, color: Colors.deepOrange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      author.isEmpty ? "Unknown author" : author,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDraft
                            ? Colors.grey.shade200
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isDraft ? 'Draft' : 'Published',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDraft
                              ? Colors.grey.shade800
                              : Colors.green.shade700,
                        ),
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
                if (isDraft) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Not visible to students until published.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
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
          if (showActions) ...[
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Colors.black87,
                    ),
                  ),
                if (onDelete != null)
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
        ],
      ),
    );
  }
}
