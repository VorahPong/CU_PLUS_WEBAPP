import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

import 'package:cu_plus_webapp/core/network/api_client.dart';
import 'package:cu_plus_webapp/features/forms/api/forms_api.dart';
import 'package:cu_plus_webapp/features/shared/widgets/page_section_header.dart';
import 'package:cu_plus_webapp/features/forms/widgets/form_renderer.dart';

class AdminFormSubmissionDetailView extends StatefulWidget {
  const AdminFormSubmissionDetailView({super.key, required this.submissionId});

  final String submissionId;

  @override
  State<AdminFormSubmissionDetailView> createState() =>
      _AdminFormSubmissionDetailViewState();
}

class _AdminFormSubmissionDetailViewState
    extends State<AdminFormSubmissionDetailView> {
  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _submission;
  Map<String, dynamic>? _form;
  List<dynamic> _fields = [];

  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, Set<String>> _checkboxValues = {};
  final Map<String, DateTime?> _dateValues = {};
  final Map<String, TextEditingController> _yearControllers = {};
  final Map<String, GlobalKey<SfSignaturePadState>> _signaturePadKeys = {};
  final Map<String, String?> _signatureValues = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSubmission();
    });
  }

  Future<void> _loadSubmission() async {
    try {
      final api = FormsApi(context.read<ApiClient>());
      final submission = await api.getAdminSubmissionDetail(
        widget.submissionId,
      );

      final formRaw = submission['formTemplate'];
      final form = formRaw is Map<String, dynamic>
          ? formRaw
          : Map<String, dynamic>.from(formRaw as Map);

      final fields = (form['fields'] as List?) ?? [];
      final answers = (submission['answers'] as List?) ?? [];

      _submission = submission;
      _form = form;
      _fields = fields;

      _textControllers.clear();
      _checkboxValues.clear();
      _dateValues.clear();
      _yearControllers.clear();
      _signaturePadKeys.clear();
      _signatureValues.clear();

      for (final rawField in _fields) {
        final field = Map<String, dynamic>.from(rawField as Map);
        final fieldId = field['id'].toString();
        final type = field['type'].toString();

        if (type == 'text' || type == 'textarea') {
          _textControllers[fieldId] = TextEditingController();
        }

        if (type == 'checkbox') {
          _checkboxValues[fieldId] = <String>{};
        }

        if (type == 'date') {
          _dateValues[fieldId] = null;
        }

        if (type == 'year') {
          _yearControllers[fieldId] = TextEditingController();
        }

        if (type == 'signature') {
          _signaturePadKeys[fieldId] = GlobalKey<SfSignaturePadState>();
          _signatureValues[fieldId] = null;
        }
      }

      final answerMap = <String, Map<String, dynamic>>{
        for (final rawAnswer in answers)
          Map<String, dynamic>.from(rawAnswer as Map)['formFieldId'].toString():
              Map<String, dynamic>.from(rawAnswer as Map),
      };

      for (final rawField in _fields) {
        final field = Map<String, dynamic>.from(rawField as Map);
        final fieldId = field['id'].toString();
        final type = field['type'].toString();
        final answer = answerMap[fieldId];

        if (answer == null) continue;

        switch (type) {
          case 'text':
          case 'textarea':
            _textControllers[fieldId]?.text = (answer['valueText'] ?? '')
                .toString();
            break;
          case 'checkbox':
            final rawValue = (answer['valueText'] ?? '').toString();
            _checkboxValues[fieldId] = rawValue
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toSet();
            break;
          case 'date':
            final rawDate = answer['valueDate'];
            if (rawDate != null) {
              _dateValues[fieldId] = DateTime.tryParse(rawDate.toString());
            }
            break;
          case 'year':
            _yearControllers[fieldId]?.text = (answer['valueText'] ?? '')
                .toString();
            break;
          case 'signature':
            _signatureValues[fieldId] = (answer['valueSignatureUrl'] ?? '')
                .toString();
            break;
        }
      }

      if (!mounted) return;

      setState(() {
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

  String _studentName() {
    final student = _submission?['student'] ?? {};
    final firstName = (student['firstName'] ?? '').toString();
    final lastName = (student['lastName'] ?? '').toString();
    return '$firstName $lastName'.trim();
  }

  String _status() {
    return (_submission?['status'] ?? '').toString();
  }

  String _gradeText() {
    return (_submission?['grade'] ?? '').toString().trim();
  }

  String _scoreText() {
    final score = _submission?['score'];
    if (score == null) return '';
    return score.toString();
  }

  String _feedbackText() {
    return (_submission?['feedback'] ?? '').toString().trim();
  }

  ButtonStyle _outlinedActionButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.black,
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  ButtonStyle _primaryActionButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
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
          Flexible(
            child: Text(
              status.isEmpty ? 'unknown' : status.replaceAll('_', ' '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
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
                          color: const Color(0xFFFFF4CC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.assignment_return_outlined,
                          color: Color(0xFFB77900),
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
                          style: _primaryActionButtonStyle(),
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

  Future<void> _returnSubmissionToDraft() async {
    final submissionId = (_submission?['id'] ?? '').toString();
    if (submissionId.isEmpty) return;

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
        const SnackBar(content: Text('Submission returned to draft successfully')),
      );

      await _loadSubmission();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _gradeSubmission() async {
    final submissionId = (_submission?['id'] ?? '').toString();
    if (submissionId.isEmpty) return;

    final gradeController = TextEditingController(text: _gradeText());
    final scoreController = TextEditingController(text: _scoreText());
    final feedbackController = TextEditingController(text: _feedbackText());

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
                            onPressed: () => Navigator.pop(dialogContext, false),
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

      await _loadSubmission();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _exportSubmissionPdf() async {
    final submissionId = (_submission?['id'] ?? '').toString();
    if (submissionId.isEmpty) return;

    try {
      final api = FormsApi(context.read<ApiClient>());
      await api.exportSubmissionPdf(submissionId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission PDF export started')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (_form?['title'] ?? 'Submission').toString();
    final instructions = (_form?['instructions'] ?? '').toString();
    final status = _status();
    final isDraft = status == 'draft';
    final isGraded = status == 'graded';
    final gradeText = _gradeText();
    final scoreText = _scoreText();
    final feedbackText = _feedbackText();

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loadSubmission,
                style: _outlinedActionButtonStyle(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 14 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 760;
              final actionButtons = Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: isNarrow ? WrapAlignment.start : WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      final formId = (_submission?['formTemplateId'] ?? '')
                          .toString();
                      context.go('/dashboard/admin/forms/$formId/submissions');
                    },
                    style: _outlinedActionButtonStyle(),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Back to Submissions'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _exportSubmissionPdf,
                    style: _outlinedActionButtonStyle(),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('Print / Export PDF'),
                  ),
                  if (!isDraft)
                    OutlinedButton.icon(
                      onPressed: _returnSubmissionToDraft,
                      style: _outlinedActionButtonStyle(),
                      icon: const Icon(Icons.assignment_return_outlined, size: 18),
                      label: const Text('Return'),
                    ),
                  ElevatedButton.icon(
                    onPressed: isDraft ? null : _gradeSubmission,
                    style: _primaryActionButtonStyle(),
                    icon: const Icon(Icons.grade_outlined, size: 18),
                    label: Text(isGraded ? 'Edit Grade' : 'Grade'),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PageSectionHeader(title: 'Submission Detail'),
                    const SizedBox(height: 12),
                    actionButtons,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PageSectionHeader(title: 'Submission Detail'),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: actionButtons,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SelectionArea(
              child: ListView(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(
                      MediaQuery.of(context).size.width < 600 ? 16 : 20,
                    ),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 520;
                            final avatar = Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF4CC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFFFD971)),
                              ),
                              child: const Icon(
                                Icons.assignment_ind_outlined,
                                color: Color(0xFFB77900),
                              ),
                            );

                            final info = Column(
                              crossAxisAlignment: isNarrow
                                  ? CrossAxisAlignment.center
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: isNarrow
                                      ? TextAlign.center
                                      : TextAlign.start,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Student: ${_studentName().isEmpty ? '-' : _studentName()}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: isNarrow
                                      ? TextAlign.center
                                      : TextAlign.start,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            );

                            if (isNarrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Center(child: avatar),
                                  const SizedBox(height: 12),
                                  info,
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                avatar,
                                const SizedBox(width: 14),
                                Expanded(child: info),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _statusChip(status),
                            if (gradeText.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  'Grade: $gradeText',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            if (scoreText.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  'Score: $scoreText',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (feedbackText.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Feedback',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SelectableText(
                                  feedbackText,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade800,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (instructions.trim().isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            instructions,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(
                      MediaQuery.of(context).size.width < 600 ? 14 : 20,
                    ),
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
                    child: FormRenderer(
                      fields: _fields,
                      readOnly: true,
                      textControllers: _textControllers,
                      checkboxValues: _checkboxValues,
                      dateValues: _dateValues,
                      yearControllers: _yearControllers,
                      signaturePadKeys: _signaturePadKeys,
                      signatureValues: _signatureValues,
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
