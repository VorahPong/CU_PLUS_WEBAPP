import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cu_plus_webapp/core/network/api_client.dart';
import 'package:cu_plus_webapp/features/forms/api/forms_api.dart';

class CreateFormView extends StatefulWidget {
  const CreateFormView({super.key});

  @override
  State<CreateFormView> createState() => _CreateFormViewState();
}

class _CreateFormViewState extends State<CreateFormView> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();

  String? _year;
  DateTime? _dueDate;

  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> _fields = [
    {
      "label": "",
      "type": "text",
      "required": false,
      "placeholder": "",
      "helpText": "",
      "sortOrder": 0,
      "configJson": null,
    },
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  void _addField() {
    setState(() {
      _fields.add({
        "label": "",
        "type": "text",
        "required": false,
        "placeholder": "",
        "helpText": "",
        "sortOrder": _fields.length,
        "configJson": null,
      });
    });
  }

  void _removeField(int index) {
    setState(() {
      _fields.removeAt(index);
      for (int i = 0; i < _fields.length; i++) {
        _fields[i]["sortOrder"] = i;
      }
    });
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    final hasEmptyFieldLabel = _fields.any(
      (field) => (field["label"] ?? "").toString().trim().isEmpty,
    );

    if (hasEmptyFieldLabel) {
      setState(() {
        _error = "Every field must have a label";
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = FormsApi(context.read<ApiClient>());

      await api.createForm(
        title: _titleCtrl.text.trim(),
        description: _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        year: _year,
        dueDate: _dueDate?.toIso8601String(),
        instructions: _instructionsCtrl.text.trim().isEmpty
            ? null
            : _instructionsCtrl.text.trim(),
        fields: _fields,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Form created successfully")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst("Exception: ", "");
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Form")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: "Form Title"),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Title is required" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _year,
              decoration: const InputDecoration(labelText: "Target Year"),
              items: const [
                DropdownMenuItem(value: null, child: Text("All Years")),
                DropdownMenuItem(value: "1", child: Text("1st Year")),
                DropdownMenuItem(value: "2", child: Text("2nd Year")),
                DropdownMenuItem(value: "3", child: Text("3rd Year")),
                DropdownMenuItem(value: "4", child: Text("4th Year")),
              ],
              onChanged: (value) => setState(() => _year = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              readOnly: true,
              onTap: _pickDueDate,
              decoration: InputDecoration(
                labelText: "Due Date",
                hintText: _dueDate == null
                    ? "Select due date"
                    : _dueDate!.toLocal().toString().split(' ').first,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _instructionsCtrl,
              decoration: const InputDecoration(labelText: "Instructions"),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            const Text(
              "Fields",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...List.generate(_fields.length, (index) {
              return _FormFieldEditor(
                key: ValueKey(index),
                field: _fields[index],
                index: index,
                onChanged: (updatedField) {
                  setState(() {
                    _fields[index] = updatedField;
                  });
                },
                onRemove: () => _removeField(index),
              );
            }),
            TextButton.icon(
              onPressed: _addField,
              icon: const Icon(Icons.add),
              label: const Text("Add Field"),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _loading ? null : _saveForm,
                child: Text(_loading ? "Saving..." : "Save Form"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormFieldEditor extends StatelessWidget {
  const _FormFieldEditor({
    super.key,
    required this.field,
    required this.index,
    required this.onChanged,
    required this.onRemove,
  });

  final Map<String, dynamic> field;
  final int index;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              initialValue: field["label"],
              decoration: InputDecoration(
                labelText: "Field ${index + 1} Label",
              ),
              onChanged: (value) {
                onChanged({...field, "label": value});
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: field["type"],
              decoration: const InputDecoration(labelText: "Field Type"),
              items: const [
                DropdownMenuItem(value: "text", child: Text("Text")),
                DropdownMenuItem(value: "textarea", child: Text("Textarea")),
                DropdownMenuItem(value: "date", child: Text("Date")),
                DropdownMenuItem(value: "checkbox", child: Text("Checkbox")),
                DropdownMenuItem(value: "signature", child: Text("Signature")),
                DropdownMenuItem(value: "year", child: Text("Year")),
              ],
              onChanged: (value) {
                onChanged({...field, "type": value});
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: field["placeholder"],
              decoration: const InputDecoration(labelText: "Placeholder"),
              onChanged: (value) {
                onChanged({...field, "placeholder": value});
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: field["helpText"],
              decoration: const InputDecoration(labelText: "Help Text"),
              onChanged: (value) {
                onChanged({...field, "helpText": value});
              },
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: field["required"] == true,
              onChanged: (value) {
                onChanged({...field, "required": value == true});
              },
              title: const Text("Required"),
              contentPadding: EdgeInsets.zero,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRemove,
                child: const Text("Remove"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
