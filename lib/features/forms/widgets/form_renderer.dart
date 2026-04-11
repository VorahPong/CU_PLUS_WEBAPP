import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

import 'form_field_widgets.dart';

class FormRenderer extends StatelessWidget {
  const FormRenderer({
    super.key,
    required this.fields,
    this.readOnly = false,
    this.textControllers = const {},
    this.checkboxValues = const {},
    this.dateValues = const {},
    this.yearControllers = const {},
    this.signaturePadKeys = const {},
    this.signatureValues = const {},
    this.onCheckboxChanged,
    this.onDateTap,
    this.onSignatureDrawEnd,
    this.onSignatureClear,
  });

  final List<dynamic> fields;
  final bool readOnly;

  final Map<String, TextEditingController> textControllers;
  final Map<String, Set<String>> checkboxValues;
  final Map<String, DateTime?> dateValues;
  final Map<String, TextEditingController> yearControllers;
  final Map<String, GlobalKey<SfSignaturePadState>> signaturePadKeys;
  final Map<String, String?> signatureValues;

  final void Function(String fieldId, String option, bool checked)?
  onCheckboxChanged;
  final void Function(String fieldId)? onDateTap;
  final VoidCallback Function(String fieldId)? onSignatureDrawEnd;
  final VoidCallback Function(String fieldId)? onSignatureClear;

  String _datePlaceholder(Map<String, dynamic> field) {
    final config = field['configJson'];
    if (config is Map && config['datePlaceholder'] != null) {
      return config['datePlaceholder'].toString();
    }
    return 'MM/DD/YYYY';
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
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return ['Option 1'];
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'MM/DD/YYYY';
    return '${date.month}/${date.day}/${date.year}';
  }

  String _signatureStatusText(String fieldId) {
    final value = signatureValues[fieldId] ?? '';
    if (readOnly) {
      return value.isNotEmpty && value.startsWith('http')
          ? 'Submitted signature'
          : 'No submitted signature available';
    }
    return value.isNotEmpty ? 'Signature captured' : 'Draw your signature above';
  }

  Widget _buildField(Map<String, dynamic> field) {
    final fieldId = field['id']?.toString() ?? '';
    final type = (field['type'] ?? '').toString();
    final label = (field['label'] ?? '').toString();
    final required = field['required'] == true;
    final placeholder = (field['placeholder'] ?? '').toString();

    final labelText = required ? '$label *' : label;

    switch (type) {
      case 'text':
        return InlineTextFormFieldWidget(
          label: labelText,
          controller: textControllers[fieldId] ?? TextEditingController(),
          hintText: placeholder.isEmpty ? 'Enter short text' : placeholder,
          readOnly: readOnly,
        );

      case 'textarea':
        return TextAreaFormFieldWidget(
          label: labelText,
          controller: textControllers[fieldId] ?? TextEditingController(),
          hintText: placeholder.isEmpty ? 'Enter description' : placeholder,
          readOnly: readOnly,
        );

      case 'checkbox':
        return CheckboxGroupFormFieldWidget(
          label: labelText,
          options: _checkboxOptions(field),
          selectedValues: checkboxValues[fieldId] ?? <String>{},
          readOnly: readOnly,
          onChanged: onCheckboxChanged == null
              ? null
              : (option, checked) {
                  onCheckboxChanged!(fieldId, option, checked);
                },
        );

      case 'date':
        return DateFormFieldWidget(
          label: labelText,
          displayText: dateValues[fieldId] == null
              ? _datePlaceholder(field)
              : _formatDate(dateValues[fieldId]),
          readOnly: readOnly,
          onTap: onDateTap == null ? null : () => onDateTap!(fieldId),
        );

      case 'year':
        return YearFormFieldWidget(
          label: labelText,
          controller: yearControllers[fieldId] ?? TextEditingController(),
          hintText: _yearPlaceholder(field),
          readOnly: readOnly,
        );

      case 'signature':
        return SignatureFormFieldWidget(
          label: labelText,
          signatureKey:
              signaturePadKeys[fieldId] ?? GlobalKey<SfSignaturePadState>(),
          readOnly: readOnly,
          imageUrl: signatureValues[fieldId],
          statusText: _signatureStatusText(fieldId),
          onDrawEnd: onSignatureDrawEnd == null
              ? null
              : onSignatureDrawEnd!(fieldId),
          onClear: onSignatureClear == null
              ? null
              : onSignatureClear!(fieldId),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Theme(
      data: readOnly
          ? Theme.of(context).copyWith(
              inputDecorationTheme: const InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
              ),
              textTheme: Theme.of(context).textTheme.apply(
                    bodyColor: Colors.black,
                    displayColor: Colors.black,
                  ),
            )
          : Theme.of(context),
      child: Column(
        children: fields.map((rawField) {
          final field = Map<String, dynamic>.from(rawField as Map);
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildField(field),
          );
        }).toList(),
      ),
    );
  }
}