import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:cu_plus_webapp/core/network/api_client.dart';
import 'package:cu_plus_webapp/features/forms/api/forms_api.dart';


class AdminFormSubmissionsView extends StatefulWidget {
  const AdminFormSubmissionsView({super.key, required this.formId});

  final String formId;

  @override
  State<AdminFormSubmissionsView> createState() =>
      _AdminFormSubmissionsViewState();
}

class _AdminFormSubmissionsViewState extends State<AdminFormSubmissionsView> {
  bool _loading = true;
  String? _error;
  List<dynamic> _submissions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSubmissions();
    });
  }

  Future<void> _loadSubmissions() async {
    try {
      final api = FormsApi(context.read<ApiClient>());
      final submissions = await api.getAdminFormSubmissions(widget.formId);

      if (!mounted) return;

      setState(() {
        _submissions = submissions;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _deleteSubmission(String submissionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Submission'),
          content: const Text(
            'Are you sure you want to delete this submission? This will also remove any uploaded signature image.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final api = FormsApi(context.read<ApiClient>());
      await api.deleteAdminSubmission(submissionId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission deleted successfully')),
      );

      await _loadSubmissions();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _studentName(dynamic submission) {
    final student = submission['student'] ?? {};
    final firstName = (student['firstName'] ?? '').toString();
    final lastName = (student['lastName'] ?? '').toString();
    final full = '$firstName $lastName'.trim();
    return full.isEmpty ? 'Unknown Student' : full;
  }

  String _studentEmail(dynamic submission) {
    final student = submission['student'] ?? {};
    return (student['email'] ?? '').toString();
  }

  String _studentSchoolId(dynamic submission) {
    final student = submission['student'] ?? {};
    return (student['schoolId'] ?? '').toString();
  }

  String _status(dynamic submission) {
    return (submission['status'] ?? '').toString();
  }

  String _formatDate(dynamic rawDate) {
    if (rawDate == null) return '-';

    final parsed = DateTime.tryParse(rawDate.toString());
    if (parsed == null) return rawDate.toString();

    return '${parsed.month}/${parsed.day}/${parsed.year}';
  }

  Widget _statusChip(String status) {
    Color bg;
    Color fg;

    switch (status) {
      case 'graded':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        break;
      case 'under_review':
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFF9A825);
        break;
      case 'returned':
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        break;
      default:
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF1565C0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.isEmpty ? 'unknown' : status,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Form Submissions',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
              ),
              OutlinedButton(
                onPressed: () {
                  context.go('/dashboard/admin/forms/${widget.formId}/preview');
                },
                child: const Text('Back to Preview'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade300, thickness: 1),
          const SizedBox(height: 20),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _loadSubmissions,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _submissions.isEmpty
                ? Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      'No submissions yet',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.separated(
                    itemCount: _submissions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final submission = _submissions[index];
                      final submissionId = (submission['id'] ?? '').toString();

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          context.go(
                            '/dashboard/admin/forms/submissions/$submissionId/detail',
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _studentName(submission),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _studentEmail(submission),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'School ID: ${_studentSchoolId(submission)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Submitted: ${_formatDate(submission['submittedAt'])}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _statusChip(_status(submission)),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'View',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      IconButton(
                                        tooltip: 'Delete submission',
                                        onPressed: () {
                                          _deleteSubmission(submissionId);
                                        },
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
    );
  }
}
