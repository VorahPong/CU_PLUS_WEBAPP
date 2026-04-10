import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

import 'package:cu_plus_webapp/core/network/api_client.dart';
import 'package:cu_plus_webapp/features/forms/api/forms_api.dart';
import 'package:cu_plus_webapp/features/forms/widgets/form_renderer.dart';

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

  @override
  Widget build(BuildContext context) {
    final title = (_form?['title'] ?? 'Form').toString();
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
              Text(
                'Preview Form',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      context.go(
                        '/dashboard/admin/forms/${widget.formId}/submissions',
                      );
                    },
                    child: const Text('View Submissions'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      context.go(
                        '/dashboard/admin/forms/${widget.formId}/edit',
                      );
                    },
                    child: const Text('Edit Form'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      context.go('/dashboard');
                    },
                    child: const Text('Back'),
                  ),
                ],
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
