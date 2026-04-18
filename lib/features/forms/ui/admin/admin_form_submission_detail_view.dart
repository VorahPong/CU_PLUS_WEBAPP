import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

import 'package:cu_plus_webapp/core/network/api_client.dart';
import 'package:cu_plus_webapp/features/forms/api/forms_api.dart';
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

  Future<void> _returnSubmissionToDraft() async {
    final submissionId = (_submission?['id'] ?? '').toString();
    if (submissionId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Return Submission to Draft'),
          content: const Text(
            'This will let the student continue editing and resubmit later. Do you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Return to Draft'),
            ),
          ],
        );
      },
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
      builder: (context) {
        return AlertDialog(
          title: const Text('Grade Submission'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: gradeController,
                  decoration: const InputDecoration(
                    labelText: 'Grade',
                    hintText: 'A, B+, Pass, etc.',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: scoreController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Score',
                    hintText: '95',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: feedbackController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Feedback',
                    hintText: 'Optional feedback for the student',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save Grade'),
            ),
          ],
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: SelectableText(_error!));
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Submission Detail',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      final formId = (_submission?['formTemplateId'] ?? '')
                          .toString();
                      context.go('/dashboard/admin/forms/$formId/submissions');
                    },
                    child: const Text('Back to Submissions'),
                  ),
                  if (!isDraft)
                    OutlinedButton(
                      onPressed: _returnSubmissionToDraft,
                      child: const Text('Return'),
                    ),
                  ElevatedButton(
                    onPressed: isDraft ? null : _gradeSubmission,
                    child: Text(isGraded ? 'Edit Grade' : 'Grade'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade300, thickness: 1),
          const SizedBox(height: 20),
          Expanded(
            child: SelectionArea(
              child: ListView(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Student: ${_studentName()}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isGraded
                              ? Colors.green.shade50
                              : isDraft
                                  ? Colors.orange.shade50
                                  : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          status.isEmpty ? 'unknown' : status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isGraded
                                ? Colors.green.shade700
                                : isDraft
                                    ? Colors.orange.shade700
                                    : Colors.grey.shade800,
                          ),
                        ),
                      ),
                      if (gradeText.isNotEmpty)
                        Text(
                          'Grade: $gradeText',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (scoreText.isNotEmpty)
                        Text(
                          'Score: $scoreText',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  if (feedbackText.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
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
                    const SizedBox(height: 10),
                    Text(
                      instructions,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FormRenderer(
                    fields: _fields,
                    readOnly: true,
                    textControllers: _textControllers,
                    checkboxValues: _checkboxValues,
                    dateValues: _dateValues,
                    yearControllers: _yearControllers,
                    signaturePadKeys: _signaturePadKeys,
                    signatureValues: _signatureValues,
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
