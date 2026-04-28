import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

import 'package:cu_plus_webapp/core/network/api_client.dart';
import 'package:cu_plus_webapp/features/forms/api/forms_api.dart';
import 'package:cu_plus_webapp/features/forms/widgets/form_renderer.dart';
import 'package:cu_plus_webapp/features/shared/widgets/page_section_header.dart';

class AdminFormPreviewView extends StatefulWidget {
  const AdminFormPreviewView({super.key, required this.formId});

  final String formId;

  @override
  State<AdminFormPreviewView> createState() => _AdminFormPreviewViewState();
}

class _AdminFormPreviewViewState extends State<AdminFormPreviewView> {
  Map<String, dynamic>? _form;
  List<dynamic> _fields = [];

  bool _loading = true;
  String? _error;

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
      _loadForm();
    });
  }

  Future<void> _loadForm() async {
    try {
      final api = FormsApi(context.read<ApiClient>());
      final form = await api.getAdminFormById(widget.formId);
      final fields = (form['fields'] as List?) ?? [];

      _form = Map<String, dynamic>.from(form);
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

      if (!mounted) return;

      setState(() {
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

  Future<void> _exportFormPdf() async {
    try {
      final api = FormsApi(context.read<ApiClient>());
      await api.exportFormPdf(widget.formId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form PDF export started')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  ButtonStyle _previewActionButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.black,
      side: BorderSide(color: Colors.grey.shade300),
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = (_form?['title'] ?? 'Form').toString();
    final instructions = (_form?['instructions'] ?? '').toString();

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }

    if (_error != null) {
      return Center(child: Text(_error!));
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
                alignment: isNarrow ? WrapAlignment.start : WrapAlignment.end,
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: _exportFormPdf,
                    style: _previewActionButtonStyle(),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('Print / Export PDF'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.go(
                        '/dashboard/admin/forms/${widget.formId}/submissions',
                      );
                    },
                    style: _previewActionButtonStyle(),
                    icon: const Icon(Icons.inbox_outlined, size: 18),
                    label: const Text('View Submissions'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.go(
                        '/dashboard/admin/forms/${widget.formId}/edit',
                      );
                    },
                    style: _previewActionButtonStyle(),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Form'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.go('/dashboard');
                    },
                    style: _previewActionButtonStyle(),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Back'),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PageSectionHeader(title: 'Preview Form'),
                    const SizedBox(height: 12),
                    actionButtons,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PageSectionHeader(title: 'Preview Form'),
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
            child: ListView(
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (instructions.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    instructions,
                    overflow: TextOverflow.visible,
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

