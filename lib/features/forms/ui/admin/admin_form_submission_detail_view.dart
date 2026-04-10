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

  @override
  Widget build(BuildContext context) {
    final title = (_form?['title'] ?? 'Submission').toString();
    final instructions = (_form?['instructions'] ?? '').toString();

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
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
              OutlinedButton(
                onPressed: () {
                  final formId = (_submission?['formTemplateId'] ?? '')
                      .toString();
                  context.go('/dashboard/admin/forms/$formId/submissions');
                },
                child: const Text('Back to Submissions'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade300, thickness: 1),
          const SizedBox(height: 20),
          Expanded(
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
        ],
      ),
    );
  }
}
