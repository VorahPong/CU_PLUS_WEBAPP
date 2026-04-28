import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_client.dart';
import '../../api/student_api.dart';
import 'package:cu_plus_webapp/features/shared/widgets/page_section_header.dart';

class StudentDetailView extends StatefulWidget {
  const StudentDetailView({
    super.key,
    required this.studentId,
    this.startInEditMode = false,
  });

  final String studentId;
  final bool startInEditMode;

  @override
  State<StudentDetailView> createState() => _StudentDetailViewState();
}

class _StudentDetailViewState extends State<StudentDetailView> {
  late final StudentApi _studentApi;

  bool _loading = true;
  bool _saving = false;
  bool _isEditing = false;
  String? _error;

  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _schoolIdController = TextEditingController();
  final _nicknameController = TextEditingController();

  String _year = '';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.startInEditMode;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _studentApi = StudentApi(context.read<ApiClient>());
      _loadStudent();
    });
  }

  Future<void> _loadStudent() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final student = await _studentApi.getStudentById(widget.studentId);

      if (!mounted) return;

      setState(() {
        _firstNameController.text = student.firstName;
        _lastNameController.text = student.lastName;
        _emailController.text = student.email;
        _schoolIdController.text = student.schoolId;
        _nicknameController.text = student.nickname ?? '';
        _year = student.year;
        _isActive = student.isActive;
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

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    try {
      final updated = await _studentApi.updateStudent(
        id: widget.studentId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        schoolId: _schoolIdController.text.trim(),
        nickname: _nicknameController.text.trim().isEmpty
            ? null
            : _nicknameController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _firstNameController.text = updated.firstName;
        _lastNameController.text = updated.lastName;
        _emailController.text = updated.email;
        _schoolIdController.text = updated.schoolId;
        _nicknameController.text = updated.nickname ?? '';
        _year = updated.year;
        _isActive = updated.isActive;
        _isEditing = false;
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _formatYear(String year) {
    switch (year) {
      case '1':
        return '1st Year';
      case '2':
        return '2nd Year';
      case '3':
        return '3rd Year';
      case '4':
        return '4th Year';
      default:
        return year;
    }
  }

  ButtonStyle _outlinedActionButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.black,
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  ButtonStyle _primaryActionButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: !_isEditing ? Colors.grey.shade50 : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final statusText = _isActive ? 'Active' : 'Deactivated';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isActive ? const Color(0xFFFFF4CC) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _isActive ? const Color(0xFFFFD971) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isActive ? Icons.check_circle_outline : Icons.block_outlined,
            size: 16,
            color: _isActive ? const Color(0xFF8A5A00) : Colors.grey.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _isActive ? const Color(0xFF8A5A00) : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _schoolIdController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loadStudent,
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
                alignment: isNarrow ? WrapAlignment.start : WrapAlignment.end,
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      context.go('/dashboard/admin/students');
                    },
                    style: _outlinedActionButtonStyle(),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Back'),
                  ),
                  if (!_isEditing)
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                      style: _primaryActionButtonStyle(),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    )
                  else ...[
                    OutlinedButton.icon(
                      onPressed: _saving
                          ? null
                          : () {
                              setState(() {
                                _isEditing = false;
                              });
                              _loadStudent();
                            },
                      style: _outlinedActionButtonStyle(),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Cancel'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _saveStudent,
                      style: _primaryActionButtonStyle(),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Save Changes'),
                    ),
                  ],
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PageSectionHeader(title: 'Student Detail'),
                    const SizedBox(height: 12),
                    actionButtons,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PageSectionHeader(title: 'Student Detail'),
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
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(
                      MediaQuery.of(context).size.width < 600 ? 16 : 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isNarrow = constraints.maxWidth < 520;

                              final fullName = '${_firstNameController.text} ${_lastNameController.text}'.trim();

                              final avatar = Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF4CC),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: const Color(0xFFFFD971)),
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  color: Color(0xFFB77900),
                                  size: 36,
                                ),
                              );

                              final info = Column(
                                crossAxisAlignment: isNarrow
                                    ? CrossAxisAlignment.center
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName.isEmpty ? 'Student Profile' : fullName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: isNarrow ? TextAlign.center : TextAlign.start,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _emailController.text,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: isNarrow ? TextAlign.center : TextAlign.start,
                                    style: TextStyle(color: Colors.grey.shade700),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildStatusBadge(),
                                ],
                              );

                              if (isNarrow) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Center(child: avatar),
                                    const SizedBox(height: 14),
                                    info,
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  avatar,
                                  const SizedBox(width: 18),
                                  Expanded(child: info),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 28),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isNarrow = constraints.maxWidth < 620;

                              final firstNameField = TextFormField(
                                controller: _firstNameController,
                                readOnly: !_isEditing,
                                decoration: _inputDecoration('First Name'),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'First name is required';
                                  }
                                  return null;
                                },
                              );

                              final lastNameField = TextFormField(
                                controller: _lastNameController,
                                readOnly: !_isEditing,
                                decoration: _inputDecoration('Last Name'),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Last name is required';
                                  }
                                  return null;
                                },
                              );

                              if (isNarrow) {
                                return Column(
                                  children: [
                                    firstNameField,
                                    const SizedBox(height: 16),
                                    lastNameField,
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(child: firstNameField),
                                  const SizedBox(width: 16),
                                  Expanded(child: lastNameField),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            readOnly: !_isEditing,
                            decoration: _inputDecoration('Email'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _schoolIdController,
                            readOnly: !_isEditing,
                            decoration: _inputDecoration('School ID'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'School ID is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nicknameController,
                            readOnly: !_isEditing,
                            decoration: _inputDecoration('Nickname'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: ValueKey('year-$_year'),
                            initialValue: _formatYear(_year),
                            readOnly: true,
                            enabled: false,
                            decoration: _inputDecoration('Year'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: ValueKey('status-$_isActive'),
                            initialValue: _isActive ? 'Active' : 'Deactivated',
                            readOnly: true,
                            enabled: false,
                            decoration: _inputDecoration('Status'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
