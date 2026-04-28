import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../api/student_api.dart';
import 'package:provider/provider.dart';
import '../../../auth/controller/auth_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:cu_plus_webapp/features/shared/widgets/page_section_header.dart';

class RegisterStudentView extends StatefulWidget {
  const RegisterStudentView({super.key, required this.email});

  final String email;

  @override
  State<RegisterStudentView> createState() => _RegisterStudentViewState();
}

class _RegisterStudentViewState extends State<RegisterStudentView> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _schoolIdCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  String? _year;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _schoolIdCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final client = context.read<ApiClient>();
    final studentApi = StudentApi(client);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await studentApi.createStudent(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        schoolId: _schoolIdCtrl.text.trim(),
        year: _year!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Student created successfully")),
      );

      // go back
      context.go('/dashboard/admin/students');
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst("Exception: ", "");
      });
    } finally {
      setState(() => _loading = false);
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (!auth.isAdmin) {
      return const Center(child: Text("Access denied"));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Padding(
      padding: EdgeInsets.all(screenWidth < 600 ? 14 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageSectionHeader(title: 'Register Students'),
          const SizedBox(height: 20),

          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth < 600 ? 14 : 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
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
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          // ✅ First/Last/School ID row (stack on mobile)
                          isMobile
                              ? Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: _buildFirstName(),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: _buildLastName(),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: _buildSchoolId(),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(child: _buildFirstName()),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildLastName()),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildSchoolId()),
                                  ],
                                ),

                          const SizedBox(height: 20),

                          // ✅ Email + Year row (stack on mobile)
                          isMobile
                              ? Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: _buildEmail(),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: _buildYear(),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(child: _buildEmail()),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildYear()),
                                  ],
                                ),

                          const SizedBox(height: 20),

                          // ✅ Password + Confirm row (stack on mobile)
                          isMobile
                              ? Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: _buildPassword(),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: _buildConfirmPassword(),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(child: _buildPassword()),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildConfirmPassword()),
                                  ],
                                ),

                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                    if (isMobile)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _loading
                                ? null
                                : () => context.go('/dashboard/admin/students'),
                            style: _outlinedActionButtonStyle(),
                            icon: const Icon(Icons.arrow_back, size: 18),
                            label: const Text('Cancel'),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: _loading ? null : _onSubmit,
                            style: _primaryActionButtonStyle(),
                            icon: _loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.person_add_alt_1, size: 18),
                            label: Text(_loading ? 'Creating...' : 'Create Student'),
                          ),
                        ],
                      )
                    else
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _loading
                                  ? null
                                  : () => context.go('/dashboard/admin/students'),
                              style: _outlinedActionButtonStyle(),
                              icon: const Icon(Icons.arrow_back, size: 18),
                              label: const Text('Cancel'),
                            ),
                            ElevatedButton.icon(
                              onPressed: _loading ? null : _onSubmit,
                              style: _primaryActionButtonStyle(),
                              icon: _loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.person_add_alt_1, size: 18),
                              label: Text(_loading ? 'Creating...' : 'Create Student'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // ----------------------------
  // Helper field builders
  // ----------------------------

  Widget _fieldLabel(String text) => Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      );

  Widget _buildFirstName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel("First Name"),
        const SizedBox(height: 10),
        TextFormField(
          controller: _firstNameCtrl,
          textInputAction: TextInputAction.next,
          validator: (v) {
            if ((v ?? "").trim().isEmpty) return "First name is required";
            return null;
          },
          decoration: _inputDecoration(hint: "John"),
        ),
      ],
    );
  }

  Widget _buildLastName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel("Last Name"),
        const SizedBox(height: 10),
        TextFormField(
          controller: _lastNameCtrl,
          textInputAction: TextInputAction.next,
          validator: (v) {
            if ((v ?? "").trim().isEmpty) return "Last name is required";
            return null;
          },
          decoration: _inputDecoration(hint: "Doe"),
        ),
      ],
    );
  }

  Widget _buildSchoolId() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel("School ID"),
        const SizedBox(height: 10),
        TextFormField(
          controller: _schoolIdCtrl,
          textInputAction: TextInputAction.next,
          validator: (v) {
            if ((v ?? "").trim().isEmpty) return "School ID is required";
            return null;
          },
          decoration: _inputDecoration(hint: "2026001"),
        ),
      ],
    );
  }

  Widget _buildEmail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel("School Email"),
        const SizedBox(height: 10),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: (v) {
            final s = (v ?? "").trim();
            if (s.isEmpty) return "Email is required";
            if (!s.contains("@")) return "Enter a valid email";
            return null;
          },
          decoration: _inputDecoration(hint: "name@cameron.edu"),
        ),
      ],
    );
  }

  Widget _buildYear() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel("Year"),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _year,
          validator: (v) =>
              (v == null || v.isEmpty) ? "Year is required" : null,
          decoration: _inputDecoration(hint: "Select year"),
          dropdownColor: Colors.white,
          iconEnabledColor: Colors.black,
          style: const TextStyle(color: Colors.black, fontSize: 14),
          items: const [
            DropdownMenuItem(value: "1", child: Text("1st Year")),
            DropdownMenuItem(value: "2", child: Text("2nd Year")),
            DropdownMenuItem(value: "3", child: Text("3rd Year")),
            DropdownMenuItem(value: "4", child: Text("4th Year")),
          ],
          onChanged: (val) => setState(() => _year = val),
        ),
      ],
    );
  }

  Widget _buildPassword() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel("Password"),
        const SizedBox(height: 10),
        TextFormField(
          controller: _passCtrl,
          obscureText: _hidePassword,
          textInputAction: TextInputAction.next,
          validator: (v) {
            final s = (v ?? "");
            if (s.isEmpty) return "Password is required";
            if (s.length < 6) return "Min 6 characters";
            return null;
          },
          decoration: _inputDecoration(hint: "••••••••").copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _hidePassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF6B7280),
              ),
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmPassword() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel("Confirm Password"),
        const SizedBox(height: 10),
        TextFormField(
          controller: _confirmPassCtrl,
          obscureText: _hideConfirmPassword,
          textInputAction: TextInputAction.done,
          validator: (v) {
            final s = (v ?? "");
            if (s.isEmpty) return "Confirm password is required";
            if (s != _passCtrl.text) return "Passwords do not match";
            return null;
          },
          decoration: _inputDecoration(hint: "••••••••").copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _hideConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF6B7280),
              ),
              onPressed: () =>
                  setState(() => _hideConfirmPassword = !_hideConfirmPassword),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF6B7280)),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
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
}
