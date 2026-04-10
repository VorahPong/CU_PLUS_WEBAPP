import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cu_plus_webapp/core/network/api_client.dart';
import 'package:cu_plus_webapp/features/forms/api/forms_api.dart';
import 'package:cu_plus_webapp/features/forms/widgets/form_renderer.dart';

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

class StudentFormFillView extends StatefulWidget {
  const StudentFormFillView({super.key, required this.formId});

  final String formId;

  @override
  State<StudentFormFillView> createState() => _StudentFormFillViewState();
}

class _StudentFormFillViewState extends State<StudentFormFillView> {
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  Map<String, dynamic>? _form;
  List<dynamic> _fields = [];
  Map<String, dynamic>? _submission;

  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, Set<String>> _checkboxValues = {};
  final Map<String, DateTime?> _dateValues = {};
  final Map<String, TextEditingController> _yearControllers = {};
  final Map<String, GlobalKey<SfSignaturePadState>> _signaturePadKeys = {};
  final Map<String, String?> _signatureValues = {};

  bool get _hasSubmittedSubmission =>
      _submission != null &&
      ((_submission!['status'] ?? '').toString() != 'draft');

  bool get _isReadOnly => _hasSubmittedSubmission;

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    for (final controller in _yearControllers.values) {
      controller.dispose();
    }
    for (final key in _signaturePadKeys.values) {
      key.currentState?.clear();
    }
    super.dispose();
  }

  Future<void> _loadForm() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = FormsApi(context.read<ApiClient>());
      final response = await api.getStudentFormById(widget.formId);

      final rawForm = response['form'] ?? response;
      if (rawForm is! Map) {
        throw Exception('Invalid form response');
      }

      final form = Map<String, dynamic>.from(rawForm);
      final submissionRaw = response['submission'];
      final submission = submissionRaw is Map
          ? Map<String, dynamic>.from(submissionRaw)
          : null;
      final fields = (form['fields'] as List?) ?? [];

      _form = form;
      _submission = submission;
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

      final answers = ((_submission?['answers'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final answerMap = <String, Map<String, dynamic>>{
        for (final answer in answers) answer['formFieldId'].toString(): answer,
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
            _textControllers[fieldId]?.text =
                (answer['valueText'] ?? '').toString();
            break;
          case 'checkbox':
            final rawValue = (answer['valueText'] ?? '').toString();
            final selected = rawValue
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toSet();
            _checkboxValues[fieldId] = selected;
            break;
          case 'date':
            final rawDate = answer['valueDate'];
            if (rawDate != null) {
              _dateValues[fieldId] = DateTime.tryParse(rawDate.toString());
            }
            break;
          case 'year':
            _yearControllers[fieldId]?.text =
                (answer['valueText'] ?? '').toString();
            break;
          case 'signature':
            _signatureValues[fieldId] =
                (answer['valueSignatureUrl'] ?? '').toString();
            break;
        }
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _pickDate(String fieldId) async {
    if (_isReadOnly) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: _dateValues[fieldId] ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _dateValues[fieldId] = picked;
      });
    }
  }

  String _yearPlaceholder(Map<String, dynamic> field) {
    final config = field['configJson'];
    if (config is Map && config['yearPlaceholder'] != null) {
      return config['yearPlaceholder'].toString();
    }
    return 'YYYY';
  }

  List<String> _checkboxOptions(Map<String, dynamic> field) {
    final config = field['configJson'];
    if (config is Map && config['options'] is List) {
      return (config['options'] as List)
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }

    return ['Option 1'];
  }

  String _datePlaceholder(Map<String, dynamic> field) {
    final config = field['configJson'];
    if (config is Map && config['datePlaceholder'] != null) {
      return config['datePlaceholder'].toString();
    }
    return 'MM/DD/YYYY';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<String?> _captureSignatureAsDataUrl(String fieldId) async {
    final key = _signaturePadKeys[fieldId];
    final state = key?.currentState;
    if (state == null) return null;

    try {
      final ui.Image image = await state.toImage(pixelRatio: 1.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) return null;

      final Uint8List bytes = byteData.buffer.asUint8List();
      final base64String = base64Encode(bytes);
      return 'data:image/png;base64,$base64String';
    } catch (_) {
      return null;
    }
  }

  Future<void> _captureAllSignatures() async {
    for (final rawField in _fields) {
      final field = Map<String, dynamic>.from(rawField);
      final fieldId = field['id'].toString();
      final type = field['type'].toString();

      if (type == 'signature') {
        final dataUrl = await _captureSignatureAsDataUrl(fieldId);
        if (dataUrl != null) {
          final uploadedUrl = await _uploadSignature(dataUrl);
          if (uploadedUrl != null) {
            _signatureValues[fieldId] = uploadedUrl;
          }
        }
      }
    }
  }

  void _clearSignature(String fieldId) {
    _signaturePadKeys[fieldId]?.currentState?.clear();
    setState(() {
      _signatureValues[fieldId] = null;
    });
  }

  bool _validateRequiredFields() {
    for (final rawField in _fields) {
      final field = Map<String, dynamic>.from(rawField);
      final fieldId = field['id'].toString();
      final type = field['type'].toString();
      final required = field['required'] == true;
      if (!required) continue;

      switch (type) {
        case 'text':
        case 'textarea':
          final value = _textControllers[fieldId]?.text.trim() ?? '';
          if (value.isEmpty) return false;
          break;
        case 'checkbox':
          final values = _checkboxValues[fieldId] ?? {};
          if (values.isEmpty) return false;
          break;
        case 'date':
          if (_dateValues[fieldId] == null) return false;
          break;
        case 'year':
          final value = _yearControllers[fieldId]?.text.trim() ?? '';
          if (value.isEmpty) return false;
          break;
        case 'signature':
          final value = _signatureValues[fieldId]?.trim() ?? '';
          if (value.isEmpty) return false;
          break;
      }
    }

    return true;
  }

  List<Map<String, dynamic>> _buildAnswersPayload() {
    final List<Map<String, dynamic>> answers = [];

    for (final rawField in _fields) {
      final field = Map<String, dynamic>.from(rawField);
      final fieldId = field['id'].toString();
      final type = field['type'].toString();

      switch (type) {
        case 'text':
        case 'textarea':
          answers.add({
            'formFieldId': fieldId,
            'valueText': _textControllers[fieldId]?.text.trim(),
          });
          break;

        case 'checkbox':
          answers.add({
            'formFieldId': fieldId,
            'valueText': (_checkboxValues[fieldId] ?? {}).join(','),
          });
          break;

        case 'date':
          answers.add({
            'formFieldId': fieldId,
            'valueDate': _dateValues[fieldId]?.toIso8601String(),
          });
          break;

        case 'year':
          answers.add({
            'formFieldId': fieldId,
            'valueText': _yearControllers[fieldId]?.text.trim(),
          });
          break;

        case 'signature':
          answers.add({
            'formFieldId': fieldId,
            'valueSignatureUrl': _signatureValues[fieldId],
          });
          break;
      }
    }

    return answers;
  }

  Future<void> _submitForm() async {
    if (_isReadOnly) return;

    await _captureAllSignatures();
    if (!_validateRequiredFields()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final api = FormsApi(context.read<ApiClient>());
      await api.submitStudentForm(
        formId: widget.formId,
        answers: _buildAnswersPayload(),
        submitNow: true,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form submitted successfully')),
      );

      context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration({
    String? hintText,
    Color fillColor = const Color(0xFFF3F3F3),
  }) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black, width: 1.2),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    );
  }

  Future<String?> _uploadSignature(String dataUrl) async {
    final client = context.read<ApiClient>();
    final response = await client.postJson('/student/forms/signature', {
      'dataUrl': dataUrl,
    });

    final url = response['url']?.toString();
    return (url == null || url.isEmpty) ? null : url;
  }

  Widget _buildField(Map<String, dynamic> field) {
    final fieldId = field['id'].toString();
    final type = field['type'].toString();
    final label = (field['label'] ?? '').toString();
    final required = field['required'] == true;
    final placeholder = (field['placeholder'] ?? '').toString();

    final labelText = required ? '$label *' : label;

    switch (type) {
      case 'text':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 14,
            runSpacing: 8,
            children: [
              if (labelText.trim().isNotEmpty)
                Text(
                  labelText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              SizedBox(
                width: 220,
                child: TextFormField(
                  controller: _textControllers[fieldId],
                  enabled: !_isReadOnly,
                  maxLines: 1,
                  keyboardType: TextInputType.text,
                  decoration:
                      _inputDecoration(
                        hintText: placeholder.isEmpty
                            ? 'Enter short text'
                            : placeholder,
                        fillColor: Colors.white,
                      ).copyWith(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                ),
              ),
            ],
          ),
        );

      case 'textarea':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (labelText.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    labelText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              TextFormField(
                controller: _textControllers[fieldId],
                enabled: !_isReadOnly,
                minLines: 5,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                decoration:
                    _inputDecoration(
                      hintText: placeholder.isEmpty
                          ? 'Enter description'
                          : placeholder,
                      fillColor: Colors.white,
                    ).copyWith(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                    ),
              ),
            ],
          ),
        );

      case 'checkbox':
        final options = _checkboxOptions(field);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 18,
            runSpacing: 8,
            children: [
              if (labelText.trim().isNotEmpty)
                Text(
                  labelText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ...options.map((option) {
                final selected =
                    _checkboxValues[fieldId]?.contains(option) ?? false;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: selected,
                      onChanged: _isReadOnly
                          ? null
                          : (value) {
                              setState(() {
                                final set =
                                    _checkboxValues[fieldId] ?? <String>{};
                                if (value == true) {
                                  set.add(option);
                                } else {
                                  set.remove(option);
                                }
                                _checkboxValues[fieldId] = set;
                              });
                            },
                      visualDensity: VisualDensity.compact,
                    ),
                    Text(option, style: const TextStyle(fontSize: 14)),
                  ],
                );
              }),
            ],
          ),
        );

      case 'date':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 14,
            runSpacing: 8,
            children: [
              if (labelText.trim().isNotEmpty)
                Text(
                  labelText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              InkWell(
                onTap: _isReadOnly ? null : () => _pickDate(fieldId),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _dateValues[fieldId] == null
                            ? _datePlaceholder(field)
                            : _formatDate(_dateValues[fieldId]),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

      case 'year':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 14,
            runSpacing: 8,
            children: [
              if (labelText.trim().isNotEmpty)
                Text(
                  labelText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              SizedBox(
                width: 120,
                child: TextFormField(
                  controller: _yearControllers[fieldId],
                  enabled: !_isReadOnly,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration:
                      _inputDecoration(
                        hintText: _yearPlaceholder(field),
                        fillColor: Colors.white,
                      ).copyWith(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                ),
              ),
            ],
          ),
        );

      case 'signature':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (labelText.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    labelText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: _isReadOnly &&
                        (_signatureValues[fieldId] ?? '').isNotEmpty &&
                        _signatureValues[fieldId]!.startsWith('http')
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          _signatureValues[fieldId]!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Stack(
                              children: [
                                const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 28,
                                    color: Colors.grey,
                                  ),
                                ),
                                Positioned(
                                  left: 12,
                                  right: 12,
                                  bottom: 12,
                                  child: Container(
                                    height: 1,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                Positioned(
                                  left: 12,
                                  bottom: 0,
                                  child: Text(
                                    'Unable to load signature',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      )
                    : Stack(
                        children: [
                          IgnorePointer(
                            ignoring: _isReadOnly,
                            child: SfSignaturePad(
                              key: _signaturePadKeys[fieldId],
                              backgroundColor: Colors.white,
                              strokeColor: Colors.black,
                              minimumStrokeWidth: 1.0,
                              maximumStrokeWidth: 3.0,
                              onDrawEnd: () {
                                setState(() {
                                  _signatureValues[fieldId] = 'drawn';
                                });
                              },
                            ),
                          ),
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: Container(
                              height: 1,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          Positioned(
                            left: 12,
                            bottom: 0,
                            child: Text(
                              'Sign here',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (!_isReadOnly) ...[
                    OutlinedButton.icon(
                      onPressed: () => _clearSignature(fieldId),
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Clear'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    _isReadOnly
                        ? (((_signatureValues[fieldId] ?? '').isNotEmpty &&
                                  _signatureValues[fieldId]!.startsWith('http'))
                              ? 'Submitted signature'
                              : 'No submitted signature available')
                        : ((_signatureValues[fieldId] ?? '').isNotEmpty
                              ? 'Signature captured'
                              : 'Draw your signature above'),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _loadForm,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final title = (_form?['title'] ?? 'Form').toString();
    final instructions = (_form?['instructions'] ?? '').toString();

    final submissionStatus = (_submission?['status'] ?? '').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: ListView(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Text(
                  'Course Content',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade300, thickness: 1),
              const SizedBox(height: 20),
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
                readOnly: _isReadOnly,
                textControllers: _textControllers,
                checkboxValues: _checkboxValues,
                dateValues: _dateValues,
                yearControllers: _yearControllers,
                signaturePadKeys: _signaturePadKeys,
                signatureValues: _signatureValues,
                onCheckboxChanged: (fieldId, option, checked) {
                  setState(() {
                    final set = _checkboxValues[fieldId] ?? <String>{};
                    if (checked) {
                      set.add(option);
                    } else {
                      set.remove(option);
                    }
                    _checkboxValues[fieldId] = set;
                  });
                },
                onDateTap: (fieldId) {
                  _pickDate(fieldId);
                },
                onSignatureDrawEnd: (fieldId) {
                  return () {
                    setState(() {
                      _signatureValues[fieldId] = 'drawn';
                    });
                  };
                },
                onSignatureClear: (fieldId) {
                  return () {
                    _clearSignature(fieldId);
                  };
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: _isReadOnly
                    ? OutlinedButton(
                        onPressed: () {
                          context.go('/dashboard');
                        },
                        child: const Text('Back to Dashboard'),
                      )
                    : ElevatedButton(
                        onPressed: _submitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_submitting ? 'Submitting...' : 'Submit'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
