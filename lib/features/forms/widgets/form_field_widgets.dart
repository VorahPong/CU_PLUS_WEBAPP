import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

InputDecoration formFieldInputDecoration({
  required BuildContext context,
  required String hintText,
  Color fillColor = Colors.white,
  EdgeInsetsGeometry? contentPadding,
}) {
  return InputDecoration(
    hintText: hintText,
    isDense: true,
    filled: true,
    fillColor: fillColor,
    counterText: '',
    contentPadding:
        contentPadding ??
        const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: Colors.grey.shade400),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: Colors.grey.shade400),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: Colors.grey.shade600),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: Colors.grey.shade400),
    ),
  );
}

class FormFieldShell extends StatelessWidget {
  const FormFieldShell({
    super.key,
    required this.child,
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  });

  final Widget child;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }
}

class InlineTextFormFieldWidget extends StatelessWidget {
  const InlineTextFormFieldWidget({
    super.key,
    required this.label,
    required this.controller,
    this.hintText = 'Enter short text',
    this.readOnly = false,
    this.width = 220,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final bool readOnly;
  final double width;

  @override
  Widget build(BuildContext context) {
    return FormFieldShell(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 14,
        runSpacing: 8,
        children: [
          if (label.trim().isNotEmpty)
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          SizedBox(
            width: width,
            child: TextFormField(
              controller: controller,
              enabled: !readOnly,
              style: const TextStyle(color: Colors.black),
              maxLines: 1,
              keyboardType: TextInputType.text,
              decoration: formFieldInputDecoration(
                context: context,
                hintText: hintText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TextAreaFormFieldWidget extends StatelessWidget {
  const TextAreaFormFieldWidget({
    super.key,
    required this.label,
    required this.controller,
    this.hintText = 'Enter description',
    this.readOnly = false,
    this.minLines = 5,
    this.maxLines = 5,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final bool readOnly;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return FormFieldShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          TextFormField(
            controller: controller,
            enabled: !readOnly,
            minLines: minLines,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.black),
            keyboardType: TextInputType.multiline,
            decoration: formFieldInputDecoration(
              context: context,
              hintText: hintText,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CheckboxGroupFormFieldWidget extends StatelessWidget {
  const CheckboxGroupFormFieldWidget({
    super.key,
    required this.label,
    required this.options,
    required this.selectedValues,
    this.readOnly = false,
    this.onChanged,
  });

  final String label;
  final List<String> options;
  final Set<String> selectedValues;
  final bool readOnly;
  final void Function(String option, bool checked)? onChanged;

  @override
  Widget build(BuildContext context) {
    return FormFieldShell(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 18,
        runSpacing: 8,
        children: [
          if (label.trim().isNotEmpty)
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ...options.map((option) {
            final isSelected = selectedValues.contains(option);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: isSelected,
                  visualDensity: VisualDensity.compact,
                  onChanged: readOnly || onChanged == null
                      ? null
                      : (value) {
                          onChanged!(option, value == true);
                        },
                ),
                Text(
                  option,
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class DateFormFieldWidget extends StatelessWidget {
  const DateFormFieldWidget({
    super.key,
    required this.label,
    this.displayText = 'MM/DD/YYYY',
    this.readOnly = false,
    this.onTap,
  });

  final String label;
  final String displayText;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FormFieldShell(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 14,
        runSpacing: 8,
        children: [
          if (label.trim().isNotEmpty)
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          InkWell(
            onTap: readOnly ? null : onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    displayText,
                    style: const TextStyle(color: Colors.black),
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

class YearFormFieldWidget extends StatelessWidget {
  const YearFormFieldWidget({
    super.key,
    required this.label,
    required this.controller,
    this.hintText = 'YYYY',
    this.readOnly = false,
    this.width = 140,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final bool readOnly;
  final double width;

  @override
  Widget build(BuildContext context) {
    return FormFieldShell(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 14,
        runSpacing: 8,
        children: [
          if (label.trim().isNotEmpty)
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          SizedBox(
            width: width,
            child: TextFormField(
              controller: controller,
              enabled: !readOnly,
              keyboardType: TextInputType.number,
              maxLength: 4,
              style: const TextStyle(color: Colors.black),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: formFieldInputDecoration(
                context: context,
                hintText: hintText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SignatureFormFieldWidget extends StatelessWidget {
  const SignatureFormFieldWidget({
    super.key,
    required this.label,
    required this.signatureKey,
    required this.readOnly,
    required this.statusText,
    this.imageUrl,
    this.onDrawEnd,
    this.onClear,
  });

  final String label;
  final GlobalKey<SfSignaturePadState> signatureKey;
  final bool readOnly;
  final String statusText;
  final String? imageUrl;
  final VoidCallback? onDrawEnd;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final normalizedImageUrl = imageUrl?.trim();
    final showImage =
        normalizedImageUrl != null &&
        normalizedImageUrl.isNotEmpty &&
        normalizedImageUrl.startsWith('http');

    return FormFieldShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
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
            child: showImage
                ? Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            normalizedImageUrl!,
                            key: ValueKey(normalizedImageUrl),
                            gaplessPlayback: true,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return _SignatureFallback(
                                message: 'Unable to load signature',
                              );
                            },
                          ),
                        ),
                      ),
                      if (!readOnly && onClear != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: ElevatedButton.icon(
                            onPressed: onClear,
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Replace'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                    ],
                  )
                : Stack(
                    children: [
                      IgnorePointer(
                        ignoring: readOnly,
                        child: SfSignaturePad(
                          key: signatureKey,
                          backgroundColor: Colors.white,
                          strokeColor: Colors.black,
                          minimumStrokeWidth: 1.0,
                          maximumStrokeWidth: 3.0,
                          onDrawEnd: onDrawEnd,
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
                          style: TextStyle(fontSize: 11, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (!readOnly && onClear != null && !showImage) ...[
                OutlinedButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Clear'),
                ),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: Text(
                  statusText,
                  style: TextStyle(fontSize: 12, color: Colors.black),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignatureFallback extends StatelessWidget {
  const _SignatureFallback({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
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
          child: Container(height: 1, color: Colors.grey),
        ),
        Positioned(
          left: 12,
          bottom: 0,
          child: Text(
            message,
            style: const TextStyle(fontSize: 11, color: Colors.black),
          ),
        ),
      ],
    );
  }
}
