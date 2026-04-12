import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cu_plus_webapp/core/network/api_client.dart';
import 'package:cu_plus_webapp/features/forms/api/forms_api.dart';
import 'package:cu_plus_webapp/core/extensions/auth_extension.dart';
import '../widget/folder.dart';
import '../widget/content_item.dart';

class CourseContentView extends StatefulWidget {
  const CourseContentView({super.key, required this.email});

  final String email;

  @override
  State<CourseContentView> createState() => _CourseContentViewState();
}

class _CourseContentViewState extends State<CourseContentView> {
  List<dynamic> _forms = [];
  bool _loading = true;
  String? _error;

  bool isEditMode = true;

  List<Folder> folders = [
  Folder(
    title: "1st Year PLUS Materials",
    isExpanded: true,
    children: [
      Folder(
        title: "FALL",
        isExpanded: true,
        contents: [
          ContentItem(
            title: "1st Year - Mid-Semester Grade Check - Fall",
            dueDate: "10/20/25, 11:49 PM",
          ),
        ],
      ),
      Folder(
        title: "SPRING",
      ),
    ],
  ),
  Folder(title: "2nd Year PLUS Materials"),
  Folder(title: "3rd & 4th Year PLUS Materials"),
  Folder(title: "Volunteer Opportunities"),
  Folder(title: "Career Profiling Tools"),
];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadForms();
    });
  }

  Future<void> _loadForms() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = FormsApi(context.read<ApiClient>());
      final isAdmin = context.authRead.isAdmin;
      final forms = isAdmin
          ? await api.getAdminForms()
          : await api.getStudentForms();

      if (!mounted) return;

      setState(() {
        _forms = forms;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst("Exception: ", "");
        _loading = false;
      });
    }
  }

  String _formatDueDate(dynamic rawDate) {
    if (rawDate == null) return "No due date";

    final parsed = DateTime.tryParse(rawDate.toString());
    if (parsed == null) return rawDate.toString();

    return "${parsed.month}/${parsed.day}/${parsed.year}";
  }

  String _formatYear(dynamic year) {
    switch (year?.toString()) {
      case '1':
        return '1st Year';
      case '2':
        return '2nd Year';
      case '3':
        return '3rd Year';
      case '4':
        return '4th Year';
      case null:
      case '':
        return 'All Years';
      default:
        return year.toString();
    }
  }

  Future<void> _showCreateFolderDialog() async {
    final TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create New Folder"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Enter folder name",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    folders.add(Folder(title: controller.text.trim()));
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddSubfolderDialog(Folder parentFolder) async {
    final TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Subfolder"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Enter subfolder name",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    parentFolder.children.add(
                      Folder(title: controller.text.trim()),
                    );
                    parentFolder.isExpanded = true;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditFolderDialog(Folder folder) async {
    final TextEditingController controller = TextEditingController(
      text: folder.title,
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Folder Name"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Enter folder name",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    folder.title = controller.text.trim();
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFolderTile(
  Folder folder, {
  int? folderIndex,
  double leftPadding = 0,
  bool isTopLevel = false,
}) {
  return Container(
    margin: EdgeInsets.only(
      bottom: 16,
      left: leftPadding,
    ),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                folder.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isEditMode)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () {
                      _showEditFolderDialog(folder);
                    },
                  ),

                if (isEditMode)
                  OutlinedButton.icon(
                    onPressed: () {
                      _showAddSubfolderDialog(folder);
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("Add Content"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    folder.isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                  onPressed: () {
                    setState(() {
                      folder.isExpanded = !folder.isExpanded;
                    });
                  },
                ),
                if (isEditMode && isTopLevel && folderIndex != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        folders.removeAt(folderIndex);
                      });
                    },
                  ),
              ],
            ),
          ],
        ),

        if (folder.isExpanded) ...[
          const SizedBox(height: 8),

          // Child folders
          ...folder.children.map(
            (childFolder) => _buildFolderTile(
              childFolder,
              leftPadding: 24,
            ),
          ),

          // Content items
          ...folder.contents.map(
            (content) => Container(
              margin: const EdgeInsets.only(left: 24, top: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(content.title),
                subtitle: content.dueDate != null
                    ? Text(
                        "Due: ${content.dueDate}",
                        style: TextStyle(color: Colors.grey.shade600),
                      )
                    : null,
                trailing: isEditMode
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () {
                              // content edit later
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                folder.contents.remove(content);
                              });
                            },
                          ),
                        ],
                      )
                    : null,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.auth.isAdmin;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Course Content",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Logged in as: ${widget.email}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  if (isAdmin) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              const Text(
                                "Toggle Edit Mode",
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 12),
                              Switch(
                                value: isEditMode,
                                onChanged: (value) {
                                  setState(() {
                                    isEditMode = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _showCreateFolderDialog,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text("Create new folder"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: folders.isEmpty
                          ? const Center(
                              child: Text(
                                "No folders created yet",
                                style: TextStyle(fontSize: 18),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: folders.length,
                              itemBuilder: (context, index) {
                                final folder = folders[index];
                                return _buildFolderTile(
                                  folder,
                                  folderIndex: index,
                                  isTopLevel: true,
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 24),

                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await context.push('/dashboard/admin/forms/create');
                          if (!mounted) return;
                          _loadForms();
                        },
                        icon: const Icon(Icons.add, color: Colors.black),
                        label: const Text(
                          "Create Form",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow.shade600,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.grey.shade400),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
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
                                      onPressed: _loadForms,
                                      child: const Text("Retry"),
                                    ),
                                  ],
                                ),
                              )
                            : _forms.isEmpty
                                ? const Center(
                                    child: Text(
                                      "No forms created yet",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _forms.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final form =
                                          _forms[index]
                                              as Map<String, dynamic>;
                                      final submissionCount =
                                          ((form['_count']
                                                              as Map<String,
                                                                  dynamic>?)?[
                                                          'submissions'] ??
                                                      0)
                                                  .toString();
                                      final isActive =
                                          form['isActive'] == true;
                                      final isAvailableToStudent = isAdmin
                                          ? true
                                          : form['isAvailableToStudent'] ==
                                              true;

                                      return Opacity(
                                        opacity:
                                            isAvailableToStudent ? 1 : 0.5,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          onTap: () {
                                            final formId =
                                                form['id']?.toString();
                                            if (formId == null) return;

                                            if (isAdmin) {
                                              context.go(
                                                '/dashboard/admin/forms/$formId/preview',
                                              );
                                            } else {
                                              if (!isAvailableToStudent) {
                                                return;
                                              }
                                              context.go(
                                                '/dashboard/student/forms/$formId',
                                              );
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: isAvailableToStudent
                                                  ? Colors.white
                                                  : Colors.grey.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        (form['title'] ??
                                                                'Untitled Form')
                                                            .toString(),
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    if (isAdmin)
                                                      OutlinedButton.icon(
                                                        onPressed: () {
                                                          final formId =
                                                              form['id']
                                                                  ?.toString();
                                                          if (formId != null) {
                                                            context.go(
                                                              '/dashboard/admin/forms/$formId/edit',
                                                            );
                                                          }
                                                        },
                                                        icon: const Icon(
                                                          Icons.edit_outlined,
                                                          size: 16,
                                                        ),
                                                        label: const Text(
                                                          'Edit',
                                                        ),
                                                        style:
                                                            OutlinedButton.styleFrom(
                                                          foregroundColor:
                                                              Colors.black87,
                                                          side: BorderSide(
                                                            color: Colors
                                                                .grey.shade300,
                                                          ),
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 10,
                                                          ),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                              8,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    if (isAdmin)
                                                      const SizedBox(width: 8),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: isActive
                                                            ? const Color(
                                                                0xFFE8F5E9,
                                                              )
                                                            : const Color(
                                                                0xFFFFEBEE,
                                                              ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                          999,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        isActive
                                                            ? 'Active'
                                                            : 'Inactive',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: isActive
                                                              ? const Color(
                                                                  0xFF2E7D32,
                                                                )
                                                              : const Color(
                                                                  0xFFC62828,
                                                                ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  (form['description'] ??
                                                          'No description')
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                        Colors.grey.shade700,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Wrap(
                                                  spacing: 12,
                                                  runSpacing: 8,
                                                  children: [
                                                    _InfoChip(
                                                      label:
                                                          'Year: ${_formatYear(form['year'])}',
                                                    ),
                                                    _InfoChip(
                                                      label:
                                                          'Due: ${_formatDueDate(form['dueDate'])}',
                                                    ),
                                                    _InfoChip(
                                                      label:
                                                          'Submissions: $submissionCount',
                                                      onPressed: isAdmin
                                                          ? () {
                                                              final formId =
                                                                  form['id']
                                                                      ?.toString();
                                                              if (formId ==
                                                                  null) {
                                                                return;
                                                              }
                                                              context.go(
                                                                '/dashboard/admin/forms/$formId/submissions',
                                                              );
                                                            }
                                                          : null,
                                                    ),
                                                    if (!isAdmin &&
                                                        !isAvailableToStudent)
                                                      const _InfoChip(
                                                        label:
                                                            'Not available for your year',
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );

    if (onPressed == null) {
      return child;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onPressed,
      child: child,
    );
  }
}