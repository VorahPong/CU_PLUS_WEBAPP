import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/controller/auth_controller.dart';
import '../../api/announcement_api.dart';

import 'package:cu_plus_webapp/features/shared/widgets/page_section_header.dart';
class CreateAnnouncementPage extends StatefulWidget {
  const CreateAnnouncementPage({super.key, this.announcement});

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

  Future<void> _onSubmit({bool saveAsDraft = false}) async {
    if (!saveAsDraft && !_formKey.currentState!.validate()) return;

    final hasAudience =
        everyone || firstYear || secondYear || thirdYear || fourthYear;

    if (!saveAsDraft && !hasAudience) {
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
          saveAsDraft: saveAsDraft,
        );
      } else {
        await announcementApi.createAnnouncement(
          message: _messageController.text.trim(),
          everyone: everyone,
          firstYear: firstYear,
          secondYear: secondYear,
          thirdYear: thirdYear,
          fourthYear: fourthYear,
          saveAsDraft: saveAsDraft,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saveAsDraft
                ? (_isEditing
                      ? "Announcement draft saved successfully"
                      : "Announcement draft created successfully")
                : (_isEditing
                      ? "Announcement updated successfully"
                      : "Announcement created successfully"),
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

  ButtonStyle _outlinedActionButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.black,
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
      return const Center(child: SelectableText("Access denied"));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SelectionArea(
          child: Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 14 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageSectionHeader(title: 'Announcement/Post'),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(
                      MediaQuery.of(context).size.width < 600 ? 14 : 20,
                    ),
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
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 620;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAudienceSection(isNarrow: isNarrow),
                              const SizedBox(height: 20),
                              Expanded(
                                child: TextFormField(
                                  controller: _messageController,
                                  expands: true,
                                  minLines: null,
                                  maxLines: null,
                                  textAlignVertical: TextAlignVertical.top,
                                  validator: (value) => null,
                                  decoration: _inputDecoration(
                                    hint: "Type announcement here...",
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
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
                                  child: SelectableText(
                                    _error!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                              _buildActionButtons(isNarrow: isNarrow),
                            ],
                          );
                        },
                      ),
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


  Widget _buildAudienceSection({required bool isNarrow}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4CC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.groups_outlined,
                  color: Color(0xFFB77900),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audience',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Choose who should receive this announcement',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: isNarrow ? 8 : 12,
            runSpacing: 10,
            children: [
              _buildCheckBox(
                label: "Everyone",
                value: everyone,
                onChanged: _handleEveryoneChanged,
              ),
              _buildCheckBox(
                label: "First-Year",
                value: firstYear,
                onChanged: (value) => _handleYearChanged("first", value),
              ),
              _buildCheckBox(
                label: "Second-Year",
                value: secondYear,
                onChanged: (value) => _handleYearChanged("second", value),
              ),
              _buildCheckBox(
                label: "Third-Year",
                value: thirdYear,
                onChanged: (value) => _handleYearChanged("third", value),
              ),
              _buildCheckBox(
                label: "Fourth-Year",
                value: fourthYear,
                onChanged: (value) => _handleYearChanged("fourth", value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons({required bool isNarrow}) {
    final cancelButton = OutlinedButton.icon(
      onPressed: _loading ? null : _cancelPost,
      style: _outlinedActionButtonStyle(),
      icon: const Icon(Icons.close, size: 18),
      label: const Text("Cancel"),
    );

    final draftButton = OutlinedButton.icon(
      onPressed: _loading ? null : () => _onSubmit(saveAsDraft: true),
      style: _outlinedActionButtonStyle(),
      icon: const Icon(Icons.drafts_outlined, size: 18),
      label: const Text("Save as Draft"),
    );

    final confirmButton = ElevatedButton.icon(
      onPressed: _loading ? null : () => _onSubmit(saveAsDraft: false),
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
          : const Icon(Icons.check, size: 18),
      label: Text(_isEditing ? "Save Changes" : "Confirm"),
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          cancelButton,
          const SizedBox(height: 10),
          draftButton,
          const SizedBox(height: 10),
          confirmButton,
        ],
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 12,
        runSpacing: 10,
        children: [
          cancelButton,
          draftButton,
          confirmButton,
        ],
      ),
    );
  }

  Widget _buildCheckBox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Material(
      color: value ? const Color(0xFFFFF4CC) : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: value ? const Color(0xFFFFD971) : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: value ? FontWeight.w700 : FontWeight.w500,
                    color: value ? const Color(0xFF8A5A00) : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Checkbox(
                value: value,
                onChanged: onChanged,
                visualDensity: VisualDensity.compact,
                activeColor: Colors.black,
                checkColor: Colors.white,
                side: BorderSide(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF6B7280)),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.all(16),
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
