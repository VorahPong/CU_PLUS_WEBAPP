import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/controller/auth_controller.dart';
import '../../api/announcement_api.dart';

class CreateAnnouncementPage extends StatefulWidget {
  const CreateAnnouncementPage({
    super.key,
    this.announcement,
  });

  final Map<String, dynamic>? announcement;

  @override
  State<CreateAnnouncementPage> createState() => _CreateAnnouncementPageState();
}

class _CreateAnnouncementPageState extends State<CreateAnnouncementPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _messageController = TextEditingController();

  bool everyone = true;
  bool firstYear = false;
  bool secondYear = false;
  bool thirdYear = false;
  bool fourthYear = false;

  bool _loading = false;
  String? _error;

  bool get _isEditing => widget.announcement != null;

  @override
  void initState() {
    super.initState();

    final announcement = widget.announcement;
    if (announcement != null) {
      _messageController.text = announcement['message'] ?? '';
      everyone = announcement['everyone'] == true;
      firstYear = announcement['firstYear'] == true;
      secondYear = announcement['secondYear'] == true;
      thirdYear = announcement['thirdYear'] == true;
      fourthYear = announcement['fourthYear'] == true;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _handleEveryoneChanged(bool? value) {
    setState(() {
      everyone = value ?? false;

      if (everyone) {
        firstYear = false;
        secondYear = false;
        thirdYear = false;
        fourthYear = false;
      }
    });
  }

  void _handleYearChanged(String year, bool? value) {
    setState(() {
      if (year == "first") firstYear = value ?? false;
      if (year == "second") secondYear = value ?? false;
      if (year == "third") thirdYear = value ?? false;
      if (year == "fourth") fourthYear = value ?? false;

      if (firstYear || secondYear || thirdYear || fourthYear) {
        everyone = false;
      }
    });
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final hasAudience =
        everyone || firstYear || secondYear || thirdYear || fourthYear;

    if (!hasAudience) {
      setState(() {
        _error = "Please select at least one audience";
      });
      return;
    }

    final client = context.read<ApiClient>();
    final announcementApi = AnnouncementApi(client);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isEditing) {
        await announcementApi.updateAnnouncement(
          id: widget.announcement!['id'],
          message: _messageController.text.trim(),
          everyone: everyone,
          firstYear: firstYear,
          secondYear: secondYear,
          thirdYear: thirdYear,
          fourthYear: fourthYear,
        );
      } else {
        await announcementApi.createAnnouncement(
          message: _messageController.text.trim(),
          everyone: everyone,
          firstYear: firstYear,
          secondYear: secondYear,
          thirdYear: thirdYear,
          fourthYear: fourthYear,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? "Announcement updated successfully"
                : "Announcement created successfully",
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst("Exception: ", "");
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _cancelPost() {
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (!auth.isAdmin) {
      return const Center(child: Text("Access denied"));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  _isEditing ? "Edit Announcement/Post" : "Announcement/Post",
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade300, thickness: 1),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 20,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                "To:",
                                style: TextStyle(fontSize: 14),
                              ),
                              _buildCheckBox(
                                label: "Everyone",
                                value: everyone,
                                onChanged: _handleEveryoneChanged,
                              ),
                              _buildCheckBox(
                                label: "First-Year",
                                value: firstYear,
                                onChanged: (value) =>
                                    _handleYearChanged("first", value),
                              ),
                              _buildCheckBox(
                                label: "Second-Year",
                                value: secondYear,
                                onChanged: (value) =>
                                    _handleYearChanged("second", value),
                              ),
                              _buildCheckBox(
                                label: "Third-Year",
                                value: thirdYear,
                                onChanged: (value) =>
                                    _handleYearChanged("third", value),
                              ),
                              _buildCheckBox(
                                label: "Fourth-Year",
                                value: fourthYear,
                                onChanged: (value) =>
                                    _handleYearChanged("fourth", value),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: TextFormField(
                            controller: _messageController,
                            expands: true,
                            minLines: null,
                            maxLines: null,
                            textAlignVertical: TextAlignVertical.top,
                            validator: (value) {
                              if ((value ?? "").trim().isEmpty) {
                                return "Announcement message is required";
                              }
                              return null;
                            },
                            decoration: _inputDecoration(
                              hint: "Type announcement here...",
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: _loading ? null : _cancelPost,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                side: BorderSide(color: Colors.grey.shade400),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 14,
                                ),
                              ),
                              child: const Text("Cancel"),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _loading ? null : _onSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 14,
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isEditing ? "Save Changes" : "Confirm",
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckBox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        Checkbox(
          value: value,
          onChanged: onChanged,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF6B7280)),
      filled: true,
      fillColor: const Color(0xFFF2F2F2),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
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