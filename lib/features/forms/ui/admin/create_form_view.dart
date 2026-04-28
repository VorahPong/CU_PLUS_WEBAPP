import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cu_plus_webapp/core/network/api_client.dart';
import 'package:cu_plus_webapp/features/forms/api/forms_api.dart';

class CreateFormView extends StatefulWidget {
  const CreateFormView({super.key, this.formId});

  final String? formId;

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
  bool _hasDueDate = false;
  int _selectedHour = 11;
  int _selectedMinute = 49;
  String _selectedPeriod = 'PM';

  bool _loading = false;
  String? _error;
  bool _loadingForm = false;

  bool get _isEditMode => widget.formId != null && widget.formId!.isNotEmpty;

  final List<Map<String, dynamic>> _fields = [];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadFormForEdit();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFormForEdit() async {
    if (!_isEditMode) return;

    setState(() {
      _loadingForm = true;
      _error = null;
    });

    try {
      final api = FormsApi(context.read<ApiClient>());
      final form = await api.getAdminFormById(widget.formId!);

      final title = (form['title'] ?? '').toString();
      final description = (form['description'] ?? '').toString();
      final instructions = (form['instructions'] ?? '').toString();
      final year = form['year']?.toString();
      final dueDateRaw = form['dueDate'];
      final fieldsRaw = (form['fields'] as List?) ?? [];

      _titleCtrl.text = title;
      _descriptionCtrl.text = description;
      _instructionsCtrl.text = instructions;
      _year = year;

      DateTime? parsedDueDate;
      if (dueDateRaw != null) {
        parsedDueDate = DateTime.tryParse(dueDateRaw.toString());
      }

      _hasDueDate = parsedDueDate != null;
      _dueDate = parsedDueDate;

      if (parsedDueDate != null) {
        final hour24 = parsedDueDate.hour;
        _selectedPeriod = hour24 >= 12 ? 'PM' : 'AM';
        final hour12 = hour24 == 0
            ? 12
            : hour24 > 12
            ? hour24 - 12
            : hour24;
        _selectedHour = hour12;
        _selectedMinute = parsedDueDate.minute;
      }

      _fields
        ..clear()
        ..addAll(
          fieldsRaw.map((raw) {
            final field = Map<String, dynamic>.from(raw as Map);
            final configRaw = field['configJson'];
            final config = configRaw is Map
                ? Map<String, dynamic>.from(configRaw)
                : null;

            return {
              'label': field['label'],
              'type': field['type'],
              'required': field['required'] == true,
              'placeholder': field['placeholder'],
              'helpText': field['helpText'],
              'sortOrder': field['sortOrder'] ?? 0,
              'configJson': config,
            };
          }),
        );

      if (!mounted) return;
      setState(() {
        _loadingForm = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loadingForm = false;
      });
    }
  }

  Future<void> _submitCreateOrUpdate(FormsApi api) async {
    if (_isEditMode) {
      await api.updateForm(
        id: widget.formId!,
        title: _titleCtrl.text.trim(),
        description: _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        year: _year,
        dueDate: _hasDueDate ? _dueDate?.toIso8601String() : null,
        instructions: _instructionsCtrl.text.trim().isEmpty
            ? null
            : _instructionsCtrl.text.trim(),
        isActive: true,
        fields: _fields,
      );
    } else {
      await api.createForm(
        title: _titleCtrl.text.trim(),
        description: _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        year: _year,
        dueDate: _hasDueDate ? _dueDate?.toIso8601String() : null,
        instructions: _instructionsCtrl.text.trim().isEmpty
            ? null
            : _instructionsCtrl.text.trim(),
        fields: _fields,
      );
    }
  }

  void _addFieldOfType(String type) {
    setState(() {
      _fields.add({
        "label": _defaultLabelForType(type),
        "type": type,
        "required": false,
        "placeholder": _defaultPlaceholderForType(type),
        "helpText": "",
        "sortOrder": _fields.length,
        "configJson": type == "checkbox"
            ? {
                "options": ["Option 1"],
              }
            : type == "date"
            ? {"datePlaceholder": "MM/DD/YYYY"}
            : type == "year"
            ? {"yearPlaceholder": "YYYY"}
            : null,
      });
    });
  }

  String _defaultLabelForType(String type) {
    switch (type) {
      case "text":
        return "Text Field";
      case "checkbox":
        return "Check Box";
      case "date":
        return "Date";
      case "year":
        return "Year";
      case "signature":
        return "Signature";
      case "textarea":
        return "Description";
      default:
        return "Field";
    }
  }

  String _defaultPlaceholderForType(String type) {
    switch (type) {
      case "text":
        return "Enter short text";
      case "textarea":
        return "Enter description";
      case "date":
        return "Select date";
      case "year":
        return "Select year";
      case "signature":
        return "Signature";
      default:
        return "";
    }
  }

  void _removeField(int index) {
    setState(() {
      _fields.removeAt(index);
      for (int i = 0; i < _fields.length; i++) {
        _fields[i]["sortOrder"] = i;
      }
    });
  }

  void _updateField(int index, Map<String, dynamic> updatedField) {
    setState(() {
      _fields[index] = updatedField;
    });
  }

  void _reorderFields(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final item = _fields.removeAt(oldIndex);
      _fields.insert(newIndex, item);

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

    if (_fields.isEmpty) {
      setState(() {
        _error = "Add at least one field";
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = FormsApi(context.read<ApiClient>());
      await _submitCreateOrUpdate(api);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Form updated successfully'
                : 'Form created successfully',
          ),
        ),
      );

      if (_isEditMode) {
        context.go('/dashboard/admin/forms');
      } else {
        context.pop(true);
      }
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
    if (!_hasDueDate) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
      builder: (dialogContext, child) {
        return Theme(
          data: Theme.of(dialogContext).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              headerBackgroundColor: Colors.white,
              headerForegroundColor: Colors.black,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                if (states.contains(WidgetState.disabled)) {
                  return Colors.grey;
                }
                return Colors.black;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.black;
                }
                return Colors.transparent;
              }),
              todayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return Colors.black;
              }),
              todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.black;
                }
                return Colors.transparent;
              }),
              todayBorder: const BorderSide(color: Colors.black),
              yearForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                if (states.contains(WidgetState.disabled)) {
                  return Colors.grey;
                }
                return Colors.black;
              }),
              yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.black;
                }
                return Colors.transparent;
              }),
              confirmButtonStyle: TextButton.styleFrom(
                foregroundColor: Colors.black,
              ),
              cancelButtonStyle: TextButton.styleFrom(
                foregroundColor: Colors.black,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final hour24 = _selectedPeriod == 'AM'
          ? (_selectedHour == 12 ? 0 : _selectedHour)
          : (_selectedHour == 12 ? 12 : _selectedHour + 12);

      setState(() {
        _dueDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          hour24,
          _selectedMinute,
        );
      });
    }
  }

  void _syncDueDateTime() {
    if (!_hasDueDate) {
      setState(() {
        _dueDate = null;
      });
      return;
    }

    final baseDate = _dueDate ?? DateTime.now();
    final hour24 = _selectedPeriod == 'AM'
        ? (_selectedHour == 12 ? 0 : _selectedHour)
        : (_selectedHour == 12 ? 12 : _selectedHour + 12);

    setState(() {
      _dueDate = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        hour24,
        _selectedMinute,
      );
    });
  }

  String _formattedTime() {
    final minute = _selectedMinute.toString().padLeft(2, '0');
    return '${_selectedHour.toString().padLeft(2, '0')} : $minute';
  }

  String _formattedDueDate() {
    if (!_hasDueDate || _dueDate == null) return "No due date";
    final d = _dueDate!;
    return "${d.month}/${d.day}/${d.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditMode ? 'Edit Form' : 'Customizing',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(
                      MediaQuery.of(context).size.width < 600 ? 14 : 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: _loadingForm
                        ? const Center(child: CircularProgressIndicator())
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final isSmallScreen = constraints.maxWidth < 760;
                              final horizontalGap = isSmallScreen ? 0.0 : 28.0;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    controller: _titleCtrl,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      hintText: "Enter form title",
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? "Title is required"
                                        : null,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Due: ${_formattedDueDate()}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Divider(
                                    color: Colors.grey.shade300,
                                    height: 1,
                                  ),
                                  const SizedBox(height: 20),
                                  Expanded(
                                    child: isSmallScreen
                                        ? SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _topMetaSection(),
                                                const SizedBox(height: 20),
                                                _addInputPanel(isCompact: true),
                                                const SizedBox(height: 20),
                                                _builderCanvas(),
                                              ],
                                            ),
                                          )
                                        : Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: SingleChildScrollView(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      _topMetaSection(),
                                                      const SizedBox(
                                                        height: 20,
                                                      ),
                                                      _builderCanvas(),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: horizontalGap),
                                              _addInputPanel(),
                                            ],
                                          ),
                                  ),
                                  if (_error != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      _error!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Wrap(
                                      alignment: WrapAlignment.end,
                                      spacing: 12,
                                      runSpacing: 10,
                                      children: [
                                        OutlinedButton(
                                          onPressed: _loading
                                              ? null
                                              : () {
                                                  if (_isEditMode) {
                                                    context.go(
                                                      '/dashboard/admin/forms',
                                                    );
                                                  } else {
                                                    context.pop();
                                                  }
                                                },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.black87,
                                            side: BorderSide(
                                              color: Colors.grey.shade300,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          child: const Text("Cancel"),
                                        ),
                                        ElevatedButton(
                                          onPressed: _loading
                                              ? null
                                              : _saveForm,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.black,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          child: Text(
                                            _loading
                                                ? (_isEditMode
                                                      ? 'Updating...'
                                                      : 'Saving...')
                                                : (_isEditMode
                                                      ? 'Update'
                                                      : 'Save'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _periodDropdownItem({
    required String value,
    required IconData icon,
    required String description,
    bool compact = false,
  }) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFB77900)),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4CC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFB77900), size: 16),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _topMetaSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        final dateFieldWidth = isNarrow ? constraints.maxWidth : 160.0;
        final timeFieldWidth = isNarrow ? 95.0 : 120.0;
        final periodFieldWidth = isNarrow ? 112.0 : 120.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Name",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              decoration: _inputDecoration(),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Title is required" : null,
            ),
            const SizedBox(height: 16),

            const Text(
              "Due Date",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.start,
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: dateFieldWidth,
                  child: TextFormField(
                    readOnly: true,
                    onTap: _hasDueDate ? _pickDueDate : null,
                    decoration: _inputDecoration(
                      hintText: _hasDueDate
                          ? (_dueDate == null
                                ? "mm/dd/yyyy"
                                : _formattedDueDate())
                          : "No due date",
                    ),
                  ),
                ),
                SizedBox(
                  width: timeFieldWidth,
                  child: DropdownButtonFormField<int>(
                    value: _selectedHour,
                    decoration: _inputDecoration(),
                    items: List.generate(12, (index) {
                      final hour = index + 1;
                      return DropdownMenuItem(
                        value: hour,
                        child: Text(hour.toString().padLeft(2, '0')),
                      );
                    }),
                    onChanged: _hasDueDate
                        ? (value) {
                            if (value == null) return;
                            _selectedHour = value;
                            _syncDueDateTime();
                          }
                        : null,
                  ),
                ),
                SizedBox(
                  width: timeFieldWidth,
                  child: DropdownButtonFormField<int>(
                    value: _selectedMinute,
                    decoration: _inputDecoration(),
                    items: List.generate(60, (index) {
                      return DropdownMenuItem(
                        value: index,
                        child: Text(index.toString().padLeft(2, '0')),
                      );
                    }),
                    onChanged: _hasDueDate
                        ? (value) {
                            if (value == null) return;
                            _selectedMinute = value;
                            _syncDueDateTime();
                          }
                        : null,
                  ),
                ),
                SizedBox(
                  width: periodFieldWidth,
                  child: DropdownButtonFormField<String>(
                    value: _selectedPeriod,
                    decoration: _inputDecoration(),
                    dropdownColor: Colors.white,
                    isExpanded: true,
                    itemHeight: 50,
                    selectedItemBuilder: (context) => [
                      _periodDropdownItem(
                        value: 'AM',
                        icon: Icons.wb_sunny_outlined,
                        description: 'Morning',
                        compact: true,
                      ),
                      _periodDropdownItem(
                        value: 'PM',
                        icon: Icons.nights_stay_outlined,
                        description: 'Afternoon / Evening',
                        compact: true,
                      ),
                    ],
                    items: [
                      DropdownMenuItem(
                        value: 'AM',
                        child: _periodDropdownItem(
                          value: 'AM',
                          icon: Icons.wb_sunny_outlined,
                          description: 'Morning',
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'PM',
                        child: _periodDropdownItem(
                          value: 'PM',
                          icon: Icons.nights_stay_outlined,
                          description: 'Afternoon / Evening',
                        ),
                      ),
                    ],
                    onChanged: _hasDueDate
                        ? (value) {
                            if (value == null) return;
                            _selectedPeriod = value;
                            _syncDueDateTime();
                          }
                        : null,
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: isNarrow ? constraints.maxWidth : 180,
                    maxWidth: isNarrow ? constraints.maxWidth : 240,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: CheckboxListTile(
                      activeColor: Colors.black,
                      value: !_hasDueDate,
                      onChanged: (value) {
                        final noDate = value == true;
                        setState(() {
                          _hasDueDate = !noDate;
                          if (_hasDueDate) {
                            final base = _dueDate ?? DateTime.now();
                            final hour24 = _selectedPeriod == 'AM'
                                ? (_selectedHour == 12 ? 0 : _selectedHour)
                                : (_selectedHour == 12
                                      ? 12
                                      : _selectedHour + 12);
                            _dueDate = DateTime(
                              base.year,
                              base.month,
                              base.day,
                              hour24,
                              _selectedMinute,
                            );
                          } else {
                            _dueDate = null;
                          }
                        });
                      },
                      title: const Text(
                        'No set date',
                        style: TextStyle(fontSize: 13),
                      ),
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "Audience",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: _year,
              decoration: _inputDecoration(),
              dropdownColor: Colors.white,
              items: const [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text("All Years"),
                ),
                DropdownMenuItem<String?>(value: "1", child: Text("1st Year")),
                DropdownMenuItem<String?>(value: "2", child: Text("2nd Year")),
                DropdownMenuItem<String?>(value: "3", child: Text("3rd Year")),
                DropdownMenuItem<String?>(value: "4", child: Text("4th Year")),
              ],
              onChanged: (value) {
                setState(() {
                  _year = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Text(
              _hasDueDate
                  ? 'Selected time: ${_formattedTime()} $_selectedPeriod'
                  : 'No due date set',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            const Text(
              "Assignment Details",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _instructionsCtrl,
              maxLines: 6,
              decoration: _inputDecoration(
                hintText: "Enter assignment instructions...",
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _builderCanvas() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: _fields.isEmpty
          ? Center(
              child: Text(
                "No fields yet — add inputs from the right",
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          : ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _fields.length,
              onReorder: _reorderFields,
              proxyDecorator: (child, index, animation) {
                return Material(color: Colors.transparent, child: child);
              },
              itemBuilder: (context, index) {
                final field = _fields[index];
                return Padding(
                  key: ValueKey(
                    'form-field-$index-${field["type"]}-${field["label"]}',
                  ),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BuilderFieldTile(
                    field: field,
                    onChanged: (updated) => _updateField(index, updated),
                    onRemove: () => _removeField(index),
                    reorderIndex: index,
                  ),
                );
              },
            ),
    );
  }

  Widget _addInputPanel({bool isCompact = false}) {
    final buttons = [
      _InputTypeButton(
        icon: Icons.text_snippet_outlined,
        label: "Text Field",
        onTap: () => _addFieldOfType("text"),
        isCompact: isCompact,
      ),
      _InputTypeButton(
        icon: Icons.notes_outlined,
        label: "Text Area",
        onTap: () => _addFieldOfType("textarea"),
        isCompact: isCompact,
      ),
      _InputTypeButton(
        icon: Icons.check_box_outlined,
        label: "Check Box",
        onTap: () => _addFieldOfType("checkbox"),
        isCompact: isCompact,
      ),
      _InputTypeButton(
        icon: Icons.calendar_today_outlined,
        label: "Date",
        onTap: () => _addFieldOfType("date"),
        isCompact: isCompact,
      ),
      _InputTypeButton(
        icon: Icons.event_note_outlined,
        label: "Year",
        onTap: () => _addFieldOfType("year"),
        isCompact: isCompact,
      ),
      _InputTypeButton(
        icon: Icons.draw_outlined,
        label: "Signature",
        onTap: () => _addFieldOfType("signature"),
        isCompact: isCompact,
      ),
    ];

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                "Add input",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              SizedBox(width: 8),
              Icon(Icons.add_circle_outline, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 10, runSpacing: 10, children: buttons),
        ],
      );
    }

    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Add input",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Icon(Icons.add_circle_outline, size: 20),
              ],
            ),
          ),
          ...buttons,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFFF3F3F3),
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
}

class _BuilderFieldTile extends StatelessWidget {
  const _BuilderFieldTile({
    required this.field,
    required this.onChanged,
    required this.onRemove,
    required this.reorderIndex,
  });

  final Map<String, dynamic> field;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onRemove;
  final int reorderIndex;

  Map<String, dynamic> _checkboxConfig() {
    final config = field["configJson"];
    if (config is Map<String, dynamic>) return config;
    if (config is Map) {
      return Map<String, dynamic>.from(config);
    }
    return {
      "options": ["Option 1"],
    };
  }

  List<String> _checkboxOptions() {
    final config = _checkboxConfig();
    final rawOptions = config["options"];

    if (rawOptions is List) {
      final options = rawOptions
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (options.isNotEmpty) return options;
    }

    return ["Option 1"];
  }

  Map<String, dynamic> _dateConfig() {
    final config = field["configJson"];
    if (config is Map<String, dynamic>) return config;
    if (config is Map) {
      return Map<String, dynamic>.from(config);
    }
    return {"datePlaceholder": "MM/DD/YYYY"};
  }

  Map<String, dynamic> _yearConfig() {
    final config = field["configJson"];
    if (config is Map<String, dynamic>) return config;
    if (config is Map) {
      return Map<String, dynamic>.from(config);
    }
    return {"yearPlaceholder": "YYYY"};
  }

  Widget _buildPreviewField(BuildContext context) {
    final type = field["type"]?.toString() ?? "text";
    final label = (field["label"] ?? "").toString();

    switch (type) {
      case "checkbox":
        final options = _checkboxOptions();
        final leftText = label.trim();

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
              if (leftText.isNotEmpty)
                Text(
                  leftText.isEmpty ? "Field label" : leftText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ...options.map(
                (option) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: false,
                      onChanged: (_) {},
                      visualDensity: VisualDensity.compact,
                    ),
                    Text(option, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        );
      case "date":
        final config = _dateConfig();
        final leftText = label.trim();
        final datePlaceholder = (config["datePlaceholder"] ?? "MM/DD/YYYY")
            .toString()
            .trim();

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
              if (leftText.isNotEmpty)
                Text(
                  leftText.isEmpty ? "Field label" : leftText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              Container(
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
                      datePlaceholder.isEmpty ? "MM/DD/YYYY" : datePlaceholder,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case "year":
        final config = _yearConfig();
        final leftText = label.trim();
        final placeholder = (config["yearPlaceholder"] ?? "YYYY").toString();

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
              if (leftText.isNotEmpty)
                Text(
                  leftText.isEmpty ? "Field label" : leftText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
                child: TextFormField(
                  enabled: false,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    hintText: placeholder,
                  ),
                ),
              ),
            ],
          ),
        );
      case "signature":
        final leftText = label.trim();

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
              if (leftText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    leftText.isEmpty ? "Field label" : leftText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.draw_outlined,
                        size: 24,
                        color: Colors.grey,
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Container(height: 1, color: Colors.grey.shade500),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 0,
                      child: Text(
                        "Sign here",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case "textarea":
        final topText = label.trim();
        final placeholder = (field["placeholder"] ?? "").toString().trim();

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
              if (topText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    topText.isEmpty ? "Field label" : topText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              TextFormField(
                enabled: false,
                minLines: 5,
                maxLines: 5,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  hintText: placeholder.isEmpty
                      ? "Enter description"
                      : placeholder,
                ),
              ),
            ],
          ),
        );
      default:
        final leftText = label.trim();

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
              if (leftText.isNotEmpty)
                Text(
                  leftText.isEmpty ? "Field label" : leftText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
                child: TextFormField(
                  enabled: false,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    hintText: _hintForType(type),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _fieldActions(BuildContext context, String type, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () async {
            final type = field["type"]?.toString() ?? "text";

            if (type == "date") {
              final config = _dateConfig();
              final leftTextController = TextEditingController(text: label);
              final placeholderController = TextEditingController(
                text: (config["datePlaceholder"] ?? "MM/DD/YYYY").toString(),
              );

              final updated = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (dialogContext) {
                  return Theme(
                    data: Theme.of(dialogContext).copyWith(
                      colorScheme: Theme.of(dialogContext).colorScheme.copyWith(
                        primary: Colors.black,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                      ),
                    ),
                    child: AlertDialog(
                      backgroundColor: Colors.white,
                      surfaceTintColor: Colors.white,
                      title: const Text('Edit Date Field'),
                      content: SizedBox(
                        width: 420,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: leftTextController,
                              decoration: const InputDecoration(
                                labelText: 'Left text',
                                hintText: 'Example: Date of Birth:',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: placeholderController,
                              decoration: const InputDecoration(
                                labelText: 'Date placeholder',
                                hintText: 'MM/DD/YYYY',
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext, {
                              "label": leftTextController.text.trim(),
                              "type": field["type"],
                              "required": field["required"],
                              "placeholder": field["placeholder"],
                              "helpText": field["helpText"],
                              "sortOrder": field["sortOrder"],
                              "configJson": {
                                "datePlaceholder":
                                    placeholderController.text.trim().isEmpty
                                    ? "MM/DD/YYYY"
                                    : placeholderController.text.trim(),
                              },
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  );
                },
              );

              if (updated != null) {
                onChanged(updated);
              }

              leftTextController.dispose();
              placeholderController.dispose();
              return;
            }

            if (type == "year") {
              final leftTextController = TextEditingController(text: label);
              final updated = await showDialog<Map<String, dynamic>>(
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Edit Year Field',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.pop(dialogContext),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: leftTextController,
                              decoration: const InputDecoration(
                                labelText: 'Label',
                                hintText: 'Example: Graduation Year:',
                              ),
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Wrap(
                                spacing: 10,
                                children: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    style: TextButton.styleFrom(
                                      backgroundColor:
                                          Colors.white, // Background color
                                      foregroundColor:
                                          Colors.black, // Text and icon color
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(dialogContext, {
                                        "label": leftTextController.text.trim(),
                                        "type": field["type"],
                                        "required": field["required"],
                                        "placeholder": field["placeholder"],
                                        "helpText": field["helpText"],
                                        "sortOrder": field["sortOrder"],
                                        "configJson": {
                                          "yearPlaceholder": "YYYY",
                                        },
                                      });
                                    },
                                    child: const Text('Save'),
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

              if (updated != null) {
                onChanged(updated);
              }
              leftTextController.dispose();
              return;
            }

            if (type == "checkbox") {
              final leftTextController = TextEditingController(text: label);
              final optionControllers = _checkboxOptions()
                  .map((option) => TextEditingController(text: option))
                  .toList();

              final updated = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (dialogContext) {
                  return Theme(
                    data: Theme.of(dialogContext).copyWith(
                      colorScheme: Theme.of(dialogContext).colorScheme.copyWith(
                        primary: Colors.black,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                      ),
                    ),
                    child: AlertDialog(
                      backgroundColor: Colors.white,
                      surfaceTintColor: Colors.white,
                      title: const Text('Edit Checkbox Field'),
                      content: StatefulBuilder(
                        builder: (context, setDialogState) {
                          return SizedBox(
                            width: 420,
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: leftTextController,
                                    decoration: const InputDecoration(
                                      labelText: 'Left text',
                                      hintText: 'Example: Semester:',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Checkbox options',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Column(
                                    children: List.generate(
                                      optionControllers.length,
                                      (index) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: TextField(
                                                  key: ValueKey(
                                                    'checkbox-option-$index',
                                                  ),
                                                  controller:
                                                      optionControllers[index],
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        'Option ${index + 1}',
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                onPressed:
                                                    optionControllers.length <= 1
                                                    ? null
                                                    : () {
                                                        setDialogState(() {
                                                          optionControllers[index]
                                                              .dispose();
                                                          optionControllers
                                                              .removeAt(index);
                                                        });
                                                      },
                                                icon: const Icon(
                                                  Icons.remove_circle_outline,
                                                  color: Colors.red,
                                                ),
                                                tooltip: 'Remove option',
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      onPressed: () {
                                        setDialogState(() {
                                          optionControllers.add(
                                            TextEditingController(),
                                          );
                                        });
                                      },
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add option'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final options = optionControllers
                                .map((controller) => controller.text.trim())
                                .where((text) => text.isNotEmpty)
                                .toList();

                            Navigator.pop(dialogContext, {
                              "label": leftTextController.text.trim(),
                              "type": field["type"],
                              "required": field["required"],
                              "placeholder": field["placeholder"],
                              "helpText": field["helpText"],
                              "sortOrder": field["sortOrder"],
                              "configJson": {
                                "options": options.isEmpty
                                    ? ["Option 1"]
                                    : options,
                              },
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  );
                },
              );

              if (updated != null) {
                onChanged(updated);
              }
              for (final controller in optionControllers) {
                controller.dispose();
              }
              return;
            }

            if (type == "signature") {
              final leftTextController = TextEditingController(text: label);

              final updated = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (dialogContext) {
                  return Theme(
                    data: Theme.of(dialogContext).copyWith(
                      colorScheme: Theme.of(dialogContext).colorScheme.copyWith(
                        primary: Colors.black,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                      ),
                    ),
                    child: AlertDialog(
                      backgroundColor: Colors.white,
                      surfaceTintColor: Colors.white,
                      title: const Text('Edit Signature Field'),
                      content: SizedBox(
                        width: 420,
                        child: TextField(
                          controller: leftTextController,
                          decoration: const InputDecoration(
                            labelText: 'Label',
                            hintText: 'Example: Student Signature:',
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext, {
                              "label": leftTextController.text.trim(),
                              "type": field["type"],
                              "required": field["required"],
                              "placeholder": field["placeholder"],
                              "helpText": field["helpText"],
                              "sortOrder": field["sortOrder"],
                              "configJson": field["configJson"],
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  );
                },
              );

              if (updated != null) {
                onChanged(updated);
              }

              leftTextController.dispose();
              return;
            }

            final controller = TextEditingController(text: label);
            final updated = await showDialog<String>(
              context: context,
              builder: (dialogContext) {
                return Theme(
                  data: Theme.of(dialogContext).copyWith(
                    colorScheme: Theme.of(dialogContext).colorScheme.copyWith(
                      primary: Colors.black,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                    ),
                  ),
                  child: AlertDialog(
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.white,
                    title: const Text('Edit Field Label'),
                    content: TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Enter field label',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(dialogContext, controller.text.trim()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                );
              },
            );

            if (updated != null) {
              onChanged({...field, "label": updated});
            }
          },
          icon: const Icon(Icons.edit_outlined, size: 18),
          splashRadius: 18,
          tooltip: 'Edit label',
        ),
        PopupMenuButton<String>(
          tooltip: "Field Type",
          color: Colors.white,
          onSelected: (value) {
            onChanged({
              ...field,
              "type": value,
              "placeholder": _defaultPlaceholderForPopup(value),
              "configJson": value == "checkbox"
                  ? {
                      "options": ["Option 1"],
                    }
                  : value == "date"
                  ? {"datePlaceholder": "MM/DD/YYYY"}
                  : value == "year"
                  ? {"yearPlaceholder": "YYYY"}
                  : field["configJson"],
            });
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: "text",
              child: const Text("Text Field", style: TextStyle(color: Colors.black)),
            ),
            PopupMenuItem(
              value: "textarea",
              child: const Text("Text Area", style: TextStyle(color: Colors.black)),
            ),
            PopupMenuItem(
              value: "checkbox",
              child: const Text("Check Box", style: TextStyle(color: Colors.black)),
            ),
            PopupMenuItem(
              value: "date",
              child: const Text("Date", style: TextStyle(color: Colors.black)),
            ),
            PopupMenuItem(
              value: "year",
              child: const Text("Year", style: TextStyle(color: Colors.black)),
            ),
            PopupMenuItem(
              value: "signature",
              child: const Text("Signature", style: TextStyle(color: Colors.black)),
            ),
          ],
          child: Icon(Icons.tune, size: 18, color: Colors.grey.shade700),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.delete, color: Colors.red),
          splashRadius: 18,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = field["type"]?.toString() ?? "text";
    final label = field["label"]?.toString() ?? "";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF2A89D8), width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 520;

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ReorderableDragStartListener(
                      index: reorderIndex,
                      child: const SizedBox(
                        width: 24,
                        child: Center(
                          child: Icon(
                            Icons.drag_indicator,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    _fieldActions(context, type, label),
                  ],
                ),
                const SizedBox(height: 8),
                _buildPreviewField(context),
              ],
            );
          }

          return Row(
            children: [
              ReorderableDragStartListener(
                index: reorderIndex,
                child: const SizedBox(
                  width: 24,
                  child: Center(
                    child: Icon(
                      Icons.drag_indicator,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _buildPreviewField(context)),
              const SizedBox(width: 8),
              _fieldActions(context, type, label),
            ],
          );
        },
      ),
    );
  }

  static String _hintForType(String type) {
    switch (type) {
      case "textarea":
        return "Description";
      case "checkbox":
        return "Check Box";
      case "date":
        return "Date";
      case "year":
        return "Year";
      case "signature":
        return "Signature";
      default:
        return "Text Field";
    }
  }

  static String _defaultPlaceholderForPopup(String type) {
    switch (type) {
      case "text":
        return "Enter short text";
      case "textarea":
        return "Enter description";
      case "checkbox":
        return "";
      case "date":
        return "Select date";
      case "year":
        return "Select year";
      case "signature":
        return "Signature";
      default:
        return "";
    }
  }
}

class _InputTypeButton extends StatelessWidget {
  const _InputTypeButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isCompact = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isCompact ? 999 : 0),
      child: Container(
        height: isCompact ? 42 : 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isCompact ? const Color(0xFFF3F3F3) : null,
          borderRadius: BorderRadius.circular(isCompact ? 999 : 0),
          border: isCompact
              ? Border.all(color: Colors.grey.shade300)
              : Border(
                  left: BorderSide(color: Colors.grey.shade300),
                  right: BorderSide(color: Colors.grey.shade300),
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
        ),
        child: Row(
          mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Icon(icon, size: 20, color: Colors.black87),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
