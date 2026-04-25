import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cu_plus_webapp/core/network/api_client.dart';
import 'package:cu_plus_webapp/features/courseContent/api/course_content_api.dart';
import 'package:cu_plus_webapp/features/forms/api/forms_api.dart';
import 'package:cu_plus_webapp/core/extensions/auth_extension.dart';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

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

  bool _contentLoading = true;
  String? _contentError;
  List<dynamic> _folders = [];
  List<dynamic> _rootForms = [];
  final Set<String> _expandedFolderIds = <String>{};

  static const String _expandedFoldersStorageKey =
      'course_content_expanded_folders';

  bool isEditMode = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadForms();
      _loadCourseContentTree();
    });
  }

  List<String> _collectFolderIds(List<dynamic> folders) {
    final ids = <String>[];

    for (final rawFolder in folders) {
      final folder = Map<String, dynamic>.from(rawFolder as Map);
      final id = folder['id']?.toString();
      if (id != null && id.isNotEmpty) {
        ids.add(id);
      }

      final children = (folder['children'] as List?) ?? const [];
      ids.addAll(_collectFolderIds(children));
    }

    return ids;
  }

  Future<void> _loadCourseContentTree() async {
    setState(() {
      _contentLoading = true;
      _contentError = null;
    });

    try {
      final client = context.read<ApiClient>();
      final data = await client.getJson('/course-content/tree');

      final folders = (data['folders'] as List?) ?? const [];
      final rootForms = (data['rootForms'] as List?) ?? const [];

      final validFolderIds = _collectFolderIds(folders).toSet();
      final savedExpandedIds = _loadExpandedFolderIdsFromStorage();
      final restoredExpandedIds = savedExpandedIds
          .where(validFolderIds.contains)
          .toSet();

      if (!mounted) return;

      setState(() {
        _folders = folders;
        _rootForms = rootForms;
        _expandedFolderIds
          ..clear()
          ..addAll(restoredExpandedIds);
        _contentLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _contentError = e.toString().replaceFirst('Exception: ', '');
        _contentLoading = false;
      });
    }
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
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Set<String> _loadExpandedFolderIdsFromStorage() {
    final storage = web.window.localStorage;
    final raw = storage.getItem(_expandedFoldersStorageKey);

    if (raw == null || raw.isEmpty) return <String>{};

    return raw
        .split(',')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  void _saveExpandedFolderIdsToStorage() {
    final storage = web.window.localStorage;

    storage.setItem(_expandedFoldersStorageKey, _expandedFolderIds.join(','));
  }

  String _folderId(Map<String, dynamic> folder) {
    return (folder['id'] ?? '').toString();
  }

  String _folderTitle(Map<String, dynamic> folder) {
    return (folder['title'] ?? 'Untitled Folder').toString();
  }

  List<dynamic> _folderChildren(Map<String, dynamic> folder) {
    return (folder['children'] as List?) ?? const [];
  }

  List<dynamic> _folderForms(Map<String, dynamic> folder) {
    return (folder['forms'] as List?) ?? const [];
  }

  String _formatDueDate(dynamic rawDate) {
    if (rawDate == null) return 'No due date';

    final parsed = DateTime.tryParse(rawDate.toString());
    if (parsed == null) return rawDate.toString();

    return '${parsed.month}/${parsed.day}/${parsed.year}';
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

  int _sortOrderOf(Map<String, dynamic> item) {
    final value = item['sortOrder'];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<Map<String, dynamic>> _rootItems() {
    final items = <Map<String, dynamic>>[];

    for (final rawFolder in _folders) {
      final folder = Map<String, dynamic>.from(rawFolder as Map);
      items.add({
        'type': 'folder',
        'id': folder['id'],
        'sortOrder': _sortOrderOf(folder),
        'data': folder,
      });
    }

    for (final rawForm in _rootForms) {
      final form = Map<String, dynamic>.from(rawForm as Map);
      items.add({
        'type': 'form',
        'id': form['id'],
        'sortOrder': _sortOrderOf(form),
        'data': form,
      });
    }

    items.sort((a, b) => _sortOrderOf(a).compareTo(_sortOrderOf(b)));
    return items;
  }

  List<Map<String, dynamic>> _folderItems(Map<String, dynamic> folder) {
    final items = <Map<String, dynamic>>[];

    for (final rawChild in _folderChildren(folder)) {
      final child = Map<String, dynamic>.from(rawChild as Map);
      items.add({
        'type': 'folder',
        'id': child['id'],
        'sortOrder': _sortOrderOf(child),
        'data': child,
      });
    }

    for (final rawForm in _folderForms(folder)) {
      final form = Map<String, dynamic>.from(rawForm as Map);
      items.add({
        'type': 'form',
        'id': form['id'],
        'sortOrder': _sortOrderOf(form),
        'data': form,
      });
    }

    items.sort((a, b) => _sortOrderOf(a).compareTo(_sortOrderOf(b)));
    return items;
  }

  Future<void> _showCreateFolderDialog() async {
    final TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Folder'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter folder name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = controller.text.trim();
                if (title.isEmpty) return;

                try {
                  final api = CourseContentApi(context.read<ApiClient>());
                  await api.createRootFolder(title: title);

                  if (!mounted) return;
                  Navigator.pop(context);
                  await _loadCourseContentTree();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceFirst('Exception: ', ''),
                      ),
                    ),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddSubfolderDialog(
    Map<String, dynamic> parentFolder,
  ) async {
    final TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Subfolder'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter subfolder name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = controller.text.trim();
                final parentId = _folderId(parentFolder);
                if (title.isEmpty || parentId.isEmpty) return;

                try {
                  final api = CourseContentApi(context.read<ApiClient>());
                  await api.createSubfolder(
                    parentFolderId: parentId,
                    title: title,
                  );

                  if (!mounted) return;
                  Navigator.pop(context);
                  await _loadCourseContentTree();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceFirst('Exception: ', ''),
                      ),
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditFolderDialog(Map<String, dynamic> folder) async {
    final TextEditingController controller = TextEditingController(
      text: _folderTitle(folder),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Folder Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter folder name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = controller.text.trim();
                final folderId = _folderId(folder);
                if (title.isEmpty || folderId.isEmpty) return;

                try {
                  final api = CourseContentApi(context.read<ApiClient>());
                  await api.updateFolder(folderId: folderId, title: title);

                  if (!mounted) return;
                  Navigator.pop(context);
                  await _loadCourseContentTree();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceFirst('Exception: ', ''),
                      ),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _moveForm({
    required String formId,
    String? folderId,
    int? sortOrder,
  }) async {
    final client = context.read<ApiClient>();
    await client.patchJson('/course-content/admin/forms/$formId/move', {
      'folderId': folderId,
      if (sortOrder != null) 'sortOrder': sortOrder,
    });
  }

  Future<void> _createFormInFolder(Map<String, dynamic> folder) async {
    final folderId = _folderId(folder);
    if (folderId.isEmpty) return;

    final existingFormIds = _forms
        .map((form) => (form as Map<String, dynamic>)['id']?.toString())
        .whereType<String>()
        .toSet();

    await context.push('/dashboard/admin/forms/create');
    if (!mounted) return;

    await _loadForms();
    if (!mounted) return;

    final newForms = _forms
        .map((form) => form as Map<String, dynamic>)
        .where((form) => !existingFormIds.contains(form['id']?.toString()))
        .toList();

    if (newForms.length == 1) {
      final createdFormId = newForms.first['id']?.toString();
      if (createdFormId != null) {
        try {
          final sortOrder = _folderItems(folder).length;
          await _moveForm(
            formId: createdFormId,
            folderId: folderId,
            sortOrder: sortOrder,
          );
          if (!mounted) return;
          await _loadCourseContentTree();
          return;
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
            ),
          );
        }
      }
    }
  }

  Future<void> _showAddContentOptionsDialog(Map<String, dynamic> folder) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Content'),
          content: const Text('What would you like to add?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showAddSubfolderDialog(folder);
              },
              child: const Text('Subfolder'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _createFormInFolder(folder);
              },
              child: const Text('Create Form'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteFolder(Map<String, dynamic> folder) async {
    final folderId = _folderId(folder);
    if (folderId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Folder'),
          content: Text(
            'Are you sure you want to delete "${_folderTitle(folder)}"? This will also remove any nested subfolders and contained forms will move to root if your backend is configured that way.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final api = CourseContentApi(context.read<ApiClient>());
      await api.deleteFolder(folderId);

      if (!mounted) return;
      await _loadForms();
      await _loadCourseContentTree();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _removeFormFromFolder({required String formId}) async {
    try {
      await _moveForm(
        formId: formId,
        folderId: null,
        sortOrder: _rootItems().length,
      );

      if (!mounted) return;
      await _loadCourseContentTree();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _confirmDeleteForm(String formId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Form'),
          content: const Text(
            'Are you sure you want to delete this form? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final api = FormsApi(context.read<ApiClient>());
      await api.deleteAdminForm(formId);

      if (!mounted) return;
      await _loadForms();
      await _loadCourseContentTree();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _onReorderItems({
    required String? parentFolderId,
    required List<Map<String, dynamic>> items,
    required int oldIndex,
    required int newIndex,
  }) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    if (oldIndex == newIndex) return;

    final reordered = List<Map<String, dynamic>>.from(items);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    final payload = reordered.asMap().entries.map((entry) {
      return {
        'type': entry.value['type'],
        'id': entry.value['id'],
        'sortOrder': entry.key,
      };
    }).toList();

    try {
      final client = context.read<ApiClient>();
      await client.patchJson('/course-content/admin/reorder', {
        'parentFolderId': parentFolderId,
        'items': payload,
      });

      if (!mounted) return;
      await _loadCourseContentTree();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Widget _buildMixedContentList(
    List<Map<String, dynamic>> items, {
    required String? parentFolderId,
    double leftPadding = 0,
  }) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      buildDefaultDragHandles: false,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      onReorder: (oldIndex, newIndex) {
        _onReorderItems(
          parentFolderId: parentFolderId,
          items: items,
          oldIndex: oldIndex,
          newIndex: newIndex,
        );
      },
      itemBuilder: (context, index) {
        final item = items[index];
        final type = item['type']?.toString();
        final id = item['id']?.toString() ?? '$type-$index';

        if (type == 'folder') {
          return _buildFolderTile(
            Map<String, dynamic>.from(item['data'] as Map),
            key: ValueKey('folder-$id'),
            index: index,
            leftPadding: leftPadding,
          );
        }

        return _buildFormTile(
          Map<String, dynamic>.from(item['data'] as Map),
          key: ValueKey('form-$id'),
          index: index,
          leftPadding: leftPadding,
          parentFolderId: parentFolderId,
        );
      },
    );
  }

  Widget _buildFormTile(
    Map<String, dynamic> form, {
    required Key key,
    required int index,
    required double leftPadding,
    required String? parentFolderId,
  }) {
    final formId = form['id']?.toString();
    final submissionCount =
        ((form['_count'] as Map<String, dynamic>?)?['submissions'] ?? 0)
            .toString();
    final isAdmin = context.auth.isAdmin;
    final canEdit = isAdmin && isEditMode;
    final isSubmitted = form['isSubmitted'] == true;

    return Container(
      key: key,
      margin: EdgeInsets.only(bottom: 16, left: leftPadding),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (formId == null) return;
          if (isAdmin) {
            context.go('/dashboard/admin/forms/$formId/preview');
          } else {
            context.go('/dashboard/student/forms/$formId');
          }
        },
        child: Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.description_outlined),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      (form['title'] ?? 'Untitled Form').toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (!isAdmin)
                    Padding(
                      padding: const EdgeInsets.only(right: 8, top: 2),
                      child: Icon(
                        Icons.check_circle,
                        size: 20,
                        color: isSubmitted ? Colors.green : Colors.grey,
                      ),
                    ),
                  if (canEdit)
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.drag_handle),
                      ),
                    ),
                  if (canEdit && formId != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.open_in_new, size: 20),
                          onPressed: () {
                            context.go('/dashboard/admin/forms/$formId/edit');
                          },
                        ),
                        if (parentFolderId != null)
                          IconButton(
                            tooltip: 'Remove from folder',
                            icon: const Icon(Icons.link_off, color: Colors.red),
                            onPressed: () {
                              _removeFormFromFolder(formId: formId);
                            },
                          ),
                        IconButton(
                          tooltip: 'Delete form',
                          icon: const Icon(
                            Icons.delete_forever,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            _confirmDeleteForm(formId);
                          },
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Due: ${_formatDueDate(form['dueDate'])}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _InfoChip(label: 'Year: ${_formatYear(form['year'])}'),
                  if (isAdmin)
                    _InfoChip(
                      label: 'Submissions: $submissionCount',
                      onPressed: formId == null
                          ? null
                          : () {
                              context.go(
                                '/dashboard/admin/forms/$formId/submissions',
                              );
                            },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFolderTile(
    Map<String, dynamic> folder, {
    required Key key,
    required int index,
    double leftPadding = 0,
  }) {
    final folderId = _folderId(folder);
    final title = _folderTitle(folder);
    final items = _folderItems(folder);
    final isExpanded = _expandedFolderIds.contains(folderId);
    final canEdit = context.auth.isAdmin && isEditMode;

    return Container(
      key: key,
      margin: EdgeInsets.only(bottom: 16, left: leftPadding),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 520;

              final titleWidget = Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              );

              final actions = Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (canEdit)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        _showEditFolderDialog(folder);
                      },
                    ),
                  if (canEdit)
                    OutlinedButton.icon(
                      onPressed: () {
                        _showAddContentOptionsDialog(folder);
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Content'),
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
                  if (canEdit)
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.drag_handle),
                      ),
                    ),
                  IconButton(
                    icon: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedFolderIds.remove(folderId);
                        } else {
                          _expandedFolderIds.add(folderId);
                        }
                      });

                      _saveExpandedFolderIdsToStorage();
                    },
                  ),
                  if (canEdit)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _deleteFolder(folder);
                      },
                    ),
                ],
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: titleWidget),
                        IconButton(
                          icon: Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                          ),
                          onPressed: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedFolderIds.remove(folderId);
                              } else {
                                _expandedFolderIds.add(folderId);
                              }
                            });

                            _saveExpandedFolderIdsToStorage();
                          },
                        ),
                      ],
                    ),
                    if (canEdit) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: actions,
                      ),
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleWidget),
                  const SizedBox(width: 12),
                  actions,
                ],
              );
            },
          ),
          if (isExpanded && items.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildMixedContentList(
              items,
              parentFolderId: folderId,
              leftPadding: 24,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.auth.isAdmin;
    final canEdit = isAdmin && isEditMode;
    final rootItems = _rootItems();

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
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0),
                    child: Text(
                      'Course Content',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Colors.grey.shade300, thickness: 1),
                  const SizedBox(height: 20),
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
                                'Toggle Edit Mode',
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
                        PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'folder') {
                              await _showCreateFolderDialog();
                              return;
                            }

                            if (value == 'form') {
                              await context.push(
                                '/dashboard/admin/forms/create',
                              );
                              if (!mounted) return;
                              await _loadForms();
                              await _loadCourseContentTree();
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem<String>(
                              value: 'folder',
                              child: Text('Create Folder'),
                            ),
                            PopupMenuItem<String>(
                              value: 'form',
                              child: Text('Create Form'),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_circle_outline),
                                SizedBox(width: 8),
                                Text('Create'),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _contentLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _contentError != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _contentError!,
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: _loadCourseContentTree,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : rootItems.isEmpty
                        ? const Center(
                            child: Text(
                              'No course content created yet',
                              style: TextStyle(fontSize: 18),
                            ),
                          )
                        : _buildMixedContentList(
                            rootItems,
                            parentFolderId: null,
                          ),
                  ),
                  const SizedBox(height: 20),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
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
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
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
