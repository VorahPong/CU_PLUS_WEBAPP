import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:cu_plus_webapp/core/network/api_client.dart';
import 'package:cu_plus_webapp/features/forms/api/forms_api.dart';

import 'package:cu_plus_webapp/features/shared/widgets/page_section_header.dart';

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

  ButtonStyle _outlinedActionButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.black,
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  ButtonStyle _primaryActionButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  InputDecoration _dialogInputDecoration({
    required String label,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
      ),
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isDanger
                              ? Colors.red.shade50
                              : const Color(0xFFFFF4CC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isDanger
                              ? Icons.delete_outline
                              : Icons.assignment_return_outlined,
                          color: isDanger
                              ? Colors.red
                              : const Color(0xFFB77900),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(dialogContext, false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          style: _outlinedActionButtonStyle(),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          style: isDanger
                              ? ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                )
                              : _primaryActionButtonStyle(),
                          child: Text(confirmLabel),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteSubmission(String submissionId) async {
    final confirmed = await _showConfirmDialog(
      title: 'Delete Submission',
      message:
          'Are you sure you want to delete this submission? This will also remove any uploaded signature image.',
      confirmLabel: 'Delete',
      isDanger: true,
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

  Future<void> _returnSubmissionToDraft(String submissionId) async {
    final confirmed = await _showConfirmDialog(
      title: 'Return Submission to Draft',
      message:
          'This will let the student continue editing and resubmit later. Do you want to continue?',
      confirmLabel: 'Return to Draft',
    );

    if (confirmed != true) return;

    try {
      final client = context.read<ApiClient>();
      await client.patchJson(
        '/admin/forms/submissions/$submissionId/return-to-draft',
        {},
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Submission returned to draft successfully'),
        ),
      );

      await _loadSubmissions();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _gradeSubmission(dynamic submission) async {
    final submissionId = (submission['id'] ?? '').toString();
    if (submissionId.isEmpty) return;

    final gradeController = TextEditingController(
      text: (submission['grade'] ?? '').toString(),
    );
    final scoreController = TextEditingController(
      text: submission['score'] == null ? '' : submission['score'].toString(),
    );
    final feedbackController = TextEditingController(
      text: (submission['feedback'] ?? '').toString(),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4CC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.grade_outlined,
                            color: Color(0xFFB77900),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Grade Submission',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(dialogContext, false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: gradeController,
                      decoration: _dialogInputDecoration(
                        label: 'Grade',
                        hint: 'A, B+, Pass, etc.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: scoreController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _dialogInputDecoration(
                        label: 'Score',
                        hint: '95',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: feedbackController,
                      maxLines: 4,
                      decoration: _dialogInputDecoration(
                        label: 'Feedback',
                        hint: 'Optional feedback for the student',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            style: _outlinedActionButtonStyle(),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            style: _primaryActionButtonStyle(),
                            child: const Text('Save Grade'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    if (confirmed != true) return;

    try {
      final rawScore = scoreController.text.trim();
      final parsedScore = rawScore.isEmpty ? null : num.tryParse(rawScore);

      if (rawScore.isNotEmpty && parsedScore == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Score must be a valid number')),
        );
        return;
      }

      final client = context.read<ApiClient>();
      await client.patchJson('/admin/forms/submissions/$submissionId/grade', {
        'grade': gradeController.text.trim().isEmpty
            ? null
            : gradeController.text.trim(),
        'score': parsedScore,
        'feedback': feedbackController.text.trim().isEmpty
            ? null
            : feedbackController.text.trim(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission graded successfully')),
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

  String _gradeText(dynamic submission) {
    final grade = (submission['grade'] ?? '').toString().trim();
    return grade;
  }

  String _scoreText(dynamic submission) {
    final score = submission['score'];
    if (score == null) return '';
    return score.toString();
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
    IconData icon;

    switch (status) {
      case 'graded':
        bg = const Color(0xFFFFF4CC);
        fg = const Color(0xFF8A5A00);
        icon = Icons.verified_outlined;
        break;
      case 'under_review':
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade800;
        icon = Icons.rate_review_outlined;
        break;
      case 'returned':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        icon = Icons.assignment_return_outlined;
        break;
      case 'draft':
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        icon = Icons.drafts_outlined;
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: status == 'graded'
              ? const Color(0xFFFFD971)
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 5),
          Text(
            status.isEmpty ? 'unknown' : status.replaceAll('_', ' '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _submissionCard(dynamic submission) {
    final submissionId = (submission['id'] ?? '').toString();
    final status = _status(submission);
    final isDraft = status == 'draft';
    final isGraded = status == 'graded';
    final gradeText = _gradeText(submission);
    final scoreText = _scoreText(submission);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.go('/dashboard/admin/forms/submissions/$submissionId/detail');
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 700;

              final avatar = Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4CC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD971)),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFFB77900),
                ),
              );

              final details = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _studentName(submission),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _studentEmail(submission),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'School ID: ${_studentSchoolId(submission)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Submitted: ${_formatDate(submission['submittedAt'])}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              );

              final gradeBox =
                  isGraded && (gradeText.isNotEmpty || scoreText.isNotEmpty)
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: isNarrow
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.end,
                        children: [
                          if (gradeText.isNotEmpty)
                            Text(
                              'Grade: $gradeText',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          if (scoreText.isNotEmpty)
                            Text(
                              'Score: $scoreText',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    )
                  : null;

              final actions = Wrap(
                alignment: isNarrow ? WrapAlignment.start : WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      context.go(
                        '/dashboard/admin/forms/submissions/$submissionId/detail',
                      );
                    },
                    style: _outlinedActionButtonStyle(),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('View'),
                  ),
                  if (!isDraft)
                    OutlinedButton.icon(
                      onPressed: () {
                        _returnSubmissionToDraft(submissionId);
                      },
                      style: _outlinedActionButtonStyle(),
                      icon: const Icon(
                        Icons.assignment_return_outlined,
                        size: 18,
                      ),
                      label: const Text('Return'),
                    ),
                  ElevatedButton.icon(
                    onPressed: isDraft
                        ? null
                        : () => _gradeSubmission(submission),
                    style: _primaryActionButtonStyle(),
                    icon: const Icon(Icons.grade_outlined, size: 18),
                    label: Text(isGraded ? 'Edit Grade' : 'Grade'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      _deleteSubmission(submissionId);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.red.shade200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        avatar,
                        const SizedBox(width: 12),
                        Expanded(child: details),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _statusChip(status),
                    if (gradeBox != null) ...[
                      const SizedBox(height: 10),
                      gradeBox,
                    ],
                    const SizedBox(height: 12),
                    actions,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  avatar,
                  const SizedBox(width: 14),
                  Expanded(child: details),
                  const SizedBox(width: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _statusChip(status),
                        if (gradeBox != null) ...[
                          const SizedBox(height: 8),
                          gradeBox,
                        ],
                        const SizedBox(height: 10),
                        actions,
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(
        MediaQuery.of(context).size.width < 600 ? 14 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 760;
              final backButton = OutlinedButton.icon(
                onPressed: () {
                  context.go('/dashboard/admin/forms/${widget.formId}/preview');
                },
                style: _outlinedActionButtonStyle(),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back to Preview'),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PageSectionHeader(title: 'Form Submissions'),
                    const SizedBox(height: 12),
                    backButton,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PageSectionHeader(title: 'Form Submissions'),
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: backButton),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  )
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _loadSubmissions,
                          style: _outlinedActionButtonStyle(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _submissions.isEmpty
                ? Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4CC),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.inbox_outlined,
                            color: Color(0xFFB77900),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No submissions yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _submissions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      return _submissionCard(_submissions[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
