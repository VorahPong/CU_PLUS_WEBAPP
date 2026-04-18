import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_client.dart';
import '../../api/student_api.dart';

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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      filled: !_isEditing,
      fillColor: !_isEditing ? Colors.grey.shade100 : null,
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Student Detail', style: TextStyle(fontSize: 24)),
              ),
              OutlinedButton(
                onPressed: () {
                  context.go('/dashboard/admin/students');
                },
                child: const Text('Back'),
              ),
              const SizedBox(width: 12),
              if (!_isEditing)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  child: const Text('Edit'),
                )
              else ...[
                OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () {
                          setState(() {
                            _isEditing = false;
                          });
                          _loadStudent();
                        },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saving ? null : _saveStudent,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade300, thickness: 1),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: 720,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              readOnly: !_isEditing,
                              decoration: _inputDecoration('First Name'),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'First name is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              readOnly: !_isEditing,
                              decoration: _inputDecoration('Last Name'),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Last name is required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
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
                        initialValue: _formatYear(_year),
                        readOnly: true,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Year',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _isActive ? 'Active' : 'Deactivated',
                        readOnly: true,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                      ),
                    ],
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
