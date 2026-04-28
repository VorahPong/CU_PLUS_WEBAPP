import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:cu_plus_webapp/core/network/api_client.dart';
import 'package:cu_plus_webapp/features/setting/api/settings_api.dart';
import 'package:cu_plus_webapp/features/setting/profile_refresh_notifier.dart';
import 'package:cu_plus_webapp/features/shared/widgets/page_section_header.dart';

class SettingView extends StatefulWidget {
  const SettingView({super.key});

  @override
  State<SettingView> createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingView> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _uploadingImage = false;
  String? _error;

  Map<String, dynamic>? _user;
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = SettingsApi(context.read<ApiClient>());
      final user = await api.getProfile();

      if (!mounted) return;

      _firstNameController.text = (user['firstName'] ?? '').toString();
      _lastNameController.text = (user['lastName'] ?? '').toString();
      _nameController.text = (user['name'] ?? '').toString();

      setState(() {
        _user = user;
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    try {
      final api = SettingsApi(context.read<ApiClient>());
      final user = await api.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        name: _nameController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _user = user;
        _saving = false;
      });

      profileRefreshNotifier.value++;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
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

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      final mime = _mimeTypeFromFileName(file.name);
      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';

      if (!mounted) return;
      setState(() {
        _selectedImageBytes = bytes;
        _uploadingImage = true;
      });

      final api = SettingsApi(context.read<ApiClient>());
      final user = await api.uploadProfileImage(dataUrl: dataUrl);

      if (!mounted) return;

      setState(() {
        _user = user;
        _uploadingImage = false;
      });

      profileRefreshNotifier.value++;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile picture updated')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _mimeTypeFromFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
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

  InputDecoration _inputDecoration({required String label}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade50,
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
    );
  }

  Widget _buildProfileAvatar() {
    final imageUrl = _user?['profileImageUrl']?.toString();

    ImageProvider? imageProvider;

    if (_selectedImageBytes != null) {
      imageProvider = MemoryImage(_selectedImageBytes!);
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      imageProvider = NetworkImage(imageUrl);
    }

    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFF4CC),
        border: Border.all(color: const Color(0xFFFFD971), width: 2),
      ),
      child: CircleAvatar(
        radius: 48,
        backgroundColor: const Color(0xFFFFF4CC),
        backgroundImage: imageProvider,
        child: imageProvider == null
            ? const Icon(Icons.person, size: 42, color: Color(0xFFB77900))
            : null,
      ),
    );
  }

  Widget _buildReadOnlyTile({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            value.isEmpty ? '-' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 14 : 24),
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _loadProfile,
                        style: _outlinedActionButtonStyle(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PageSectionHeader(title: 'Settings'),
                      const SizedBox(height: 20),
                      Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 760),
                          padding: const EdgeInsets.all(24),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isNarrow = constraints.maxWidth < 520;

                                    final avatar = Stack(
                                      children: [
                                        _buildProfileAvatar(),
                                        if (_uploadingImage)
                                          const Positioned.fill(
                                            child: Center(
                                              child: SizedBox(
                                                width: 28,
                                                height: 28,
                                                child: CircularProgressIndicator(
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );

                                    final profileInfo = Column(
                                      crossAxisAlignment: isNarrow
                                          ? CrossAxisAlignment.center
                                          : CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ((_user?['firstName'] ?? '').toString() +
                                                  ' ' +
                                                  ((_user?['lastName'] ?? '')
                                                      .toString()))
                                              .trim()
                                              .isEmpty
                                              ? 'User Profile'
                                              : ((_user?['firstName'] ?? '')
                                                        .toString() +
                                                    ' ' +
                                                    ((_user?['lastName'] ?? '')
                                                        .toString()))
                                                  .trim(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: isNarrow
                                              ? TextAlign.center
                                              : TextAlign.start,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          (_user?['email'] ?? '').toString(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: isNarrow
                                              ? TextAlign.center
                                              : TextAlign.start,
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        OutlinedButton.icon(
                                          onPressed: _uploadingImage
                                              ? null
                                              : _pickAndUploadImage,
                                          style: _outlinedActionButtonStyle(),
                                          icon: const Icon(Icons.photo_outlined),
                                          label: const Text('Change Profile Picture'),
                                        ),
                                      ],
                                    );

                                    if (isNarrow) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Center(child: avatar),
                                          const SizedBox(height: 16),
                                          profileInfo,
                                        ],
                                      );
                                    }

                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        avatar,
                                        const SizedBox(width: 20),
                                        Expanded(child: profileInfo),
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
                                      readOnly: true,
                                      enabled: false,
                                      decoration: _inputDecoration(label: 'First Name'),
                                    );
                                    final lastNameField = TextFormField(
                                      controller: _lastNameController,
                                      readOnly: true,
                                      enabled: false,
                                      decoration: _inputDecoration(label: 'Last Name'),
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
                                  controller: _nameController,
                                  decoration: _inputDecoration(label: 'Display Name'),
                                ),
                                const SizedBox(height: 24),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isNarrow = constraints.maxWidth < 620;
                                    final emailTile = _buildReadOnlyTile(
                                      label: 'Email',
                                      value: (_user?['email'] ?? '').toString(),
                                    );
                                    final schoolIdTile = _buildReadOnlyTile(
                                      label: 'School ID',
                                      value: (_user?['schoolId'] ?? '').toString(),
                                    );

                                    if (isNarrow) {
                                      return Column(
                                        children: [
                                          emailTile,
                                          const SizedBox(height: 16),
                                          schoolIdTile,
                                        ],
                                      );
                                    }

                                    return Row(
                                      children: [
                                        Expanded(child: emailTile),
                                        const SizedBox(width: 16),
                                        Expanded(child: schoolIdTile),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isNarrow = constraints.maxWidth < 620;
                                    final yearTile = _buildReadOnlyTile(
                                      label: 'Year',
                                      value: (_user?['year'] ?? '').toString(),
                                    );
                                    final roleTile = _buildReadOnlyTile(
                                      label: 'Role',
                                      value: (_user?['role'] ?? '').toString(),
                                    );

                                    if (isNarrow) {
                                      return Column(
                                        children: [
                                          yearTile,
                                          const SizedBox(height: 16),
                                          roleTile,
                                        ],
                                      );
                                    }

                                    return Row(
                                      children: [
                                        Expanded(child: yearTile),
                                        const SizedBox(width: 16),
                                        Expanded(child: roleTile),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton.icon(
                                    onPressed: _saving ? null : _saveProfile,
                                    style: _primaryActionButtonStyle(),
                                    icon: _saving
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.save),
                                    label: const Text('Save Changes'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
