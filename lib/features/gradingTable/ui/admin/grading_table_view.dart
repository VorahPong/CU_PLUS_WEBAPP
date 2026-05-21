import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cu_plus_webapp/core/network/api_client.dart';
import 'package:cu_plus_webapp/features/forms/api/forms_api.dart';
import 'package:cu_plus_webapp/features/shared/widgets/page_section_header.dart';

import 'package:go_router/go_router.dart';

class GradingTableView extends StatefulWidget {
  const GradingTableView({super.key});

  @override
  State<GradingTableView> createState() => _GradingTableViewState();
}

class _GradingTableViewState extends State<GradingTableView> {
  bool _loading = true;
  String? _error;
  List<dynamic> _forms = [];
  List<_GradingRowState> _rows = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      final api = FormsApi(context.read<ApiClient>());
      final forms = await api.getAdminForms();

      final rows = <_GradingRowState>[];

      for (final form in forms) {
        final formId = (form['id'] ?? '').toString();
        if (formId.isEmpty) continue;

        final submissions = await api.getAdminFormSubmissions(formId);

        for (final submission in submissions) {
          rows.add(
            _GradingRowState(
              formId: formId,
              formTitle: (form['title'] ?? 'Untitled Form').toString(),
              submission: submission,
            ),
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _forms = forms;
        _rows = rows;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  ButtonStyle _outlinedButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.black,
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  ButtonStyle _compactOutlinedButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.black,
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      minimumSize: const Size(0, 40),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  ButtonStyle _compactPrimaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      minimumSize: const Size(0, 40),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black, width: 1.4),
      ),
    );
  }

  List<_GradingRowState> get _filteredRows {
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) return _rows;

    return _rows.where((row) {
      return row.studentName.toLowerCase().contains(query) ||
          row.schoolId.toLowerCase().contains(query) ||
          row.formTitle.toLowerCase().contains(query) ||
          row.email.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _saveRow(_GradingRowState row) async {
    setState(() => row.saving = true);

    try {
      final client = context.read<ApiClient>();

      await client.patchJson('/admin/forms/submissions/${row.submissionId}/grade', {
        'grade': row.gradeStatus == 'graded' ? 'Graded' : 'Not Graded',
      });

      if (!mounted) return;

      setState(() {
        row.saving = false;
        row.dirty = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Grade saved successfully')));
    } catch (e) {
      if (!mounted) return;

      setState(() => row.saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _viewSubmissionDetail(_GradingRowState row) {
    if (row.submissionId.isEmpty) return;
    context.go('/dashboard/admin/forms/submissions/${row.submissionId}/detail');
  }

  Widget _desktopTable(List<_GradingRowState> rows) {
    return Container(
      width: double.infinity,
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
          headingRowColor: WidgetStatePropertyAll(Colors.grey.shade100),
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('Student')),
            DataColumn(label: Text('School ID')),
            DataColumn(label: Text('Form')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Grade Status')),
            DataColumn(label: Text('Action')),
          ],
          rows: rows.map((row) {
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 180,
                    child: Text(
                      row.studentName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(row.schoolId.isEmpty ? '-' : row.schoolId)),
                DataCell(
                  SizedBox(
                    width: 220,
                    child: Text(row.formTitle, overflow: TextOverflow.ellipsis),
                  ),
                ),
                DataCell(_statusChip(row.status)),
                DataCell(_gradeDropdown(row)),
                DataCell(
                  SizedBox(
                    width: 210,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _viewSubmissionDetail(row),
                          style: _compactOutlinedButtonStyle(),
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text('View'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: row.saving || !row.dirty
                              ? null
                              : () => _saveRow(row),
                          style: _compactPrimaryButtonStyle(),
                          child: Text(row.saving ? 'Saving...' : 'Save'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _mobileCards(List<_GradingRowState> rows) {
    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final row = rows[index];

        return Container(
          padding: const EdgeInsets.all(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.studentName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(row.email, style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 4),
              Text('School ID: ${row.schoolId.isEmpty ? '-' : row.schoolId}'),
              const SizedBox(height: 8),
              Text(
                row.formTitle,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [_statusChip(row.status)],
              ),
              const SizedBox(height: 14),
              _gradeDropdown(row),
              // Feedback field removed
              LayoutBuilder(
                builder: (context, constraints) {
                  final isVeryNarrow = constraints.maxWidth < 420;

                  final viewButton = OutlinedButton.icon(
                    onPressed: () => _viewSubmissionDetail(row),
                    style: _outlinedButtonStyle(),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('View Detail'),
                  );

                  final saveButton = ElevatedButton.icon(
                    onPressed: row.saving || !row.dirty
                        ? null
                        : () => _saveRow(row),
                    style: _primaryButtonStyle(),
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: Text(row.saving ? 'Saving...' : 'Save'),
                  );

                  if (isVeryNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        viewButton,
                        const SizedBox(height: 10),
                        saveButton,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: viewButton),
                      const SizedBox(width: 10),
                      Expanded(child: saveButton),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _gradeDropdown(_GradingRowState row) {
    return DropdownButtonFormField<String>(
      value: row.gradeStatus,
      dropdownColor: Colors.white,
      iconEnabledColor: Colors.black,
      decoration: _inputDecoration(),
      items: const [
        DropdownMenuItem(value: 'graded', child: Text('Graded')),
        DropdownMenuItem(value: 'not_graded', child: Text('Not Graded')),
      ],
      onChanged: row.saving
          ? null
          : (value) {
              if (value == null) return;
              setState(() {
                row.gradeStatus = value;
                row.dirty = true;
              });
            },
    );
  }

  Widget _statusChip(String status) {
    final label = status.isEmpty ? 'unknown' : status.replaceAll('_', ' ');
    final isGraded = status == 'graded';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isGraded ? const Color(0xFFFFF4CC) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isGraded ? const Color(0xFFFFD971) : Colors.grey.shade300,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isGraded ? const Color(0xFF8A5A00) : Colors.grey.shade700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filteredRows;

    return Padding(
      padding: EdgeInsets.all(
        MediaQuery.of(context).size.width < 600 ? 14 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageSectionHeader(title: 'Grading Table'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: _inputDecoration(
                    hint: 'Search by student, school ID, email, or form',
                  ),
                  onChanged: (value) => setState(() => _search = value),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _loading ? null : _loadData,
                style: _outlinedButtonStyle(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  )
                : _error != null
                ? Center(
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
                          onPressed: _loadData,
                          style: _outlinedButtonStyle(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : rows.isEmpty
                ? const Center(child: Text('No submissions found'))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 760) {
                        return _mobileCards(rows);
                      }

                      return SingleChildScrollView(child: _desktopTable(rows));
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _GradingRowState {
  _GradingRowState({
    required this.formId,
    required this.formTitle,
    required this.submission,
  }) {
    final grade = (submission['grade'] ?? '').toString().toLowerCase();
    gradeStatus = grade == 'graded' ? 'graded' : 'not_graded';
  }

  final String formId;
  final String formTitle;
  final dynamic submission;

  late String gradeStatus;

  bool saving = false;
  bool dirty = false;

  String get submissionId => (submission['id'] ?? '').toString();

  Map<String, dynamic> get student {
    final raw = submission['student'];
    if (raw is Map<String, dynamic>) return raw;
    return {};
  }

  String get studentName {
    final firstName = (student['firstName'] ?? '').toString();
    final lastName = (student['lastName'] ?? '').toString();
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? 'Unknown Student' : fullName;
  }

  String get email => (student['email'] ?? '').toString();

  String get schoolId => (student['schoolId'] ?? '').toString();

  String get status => (submission['status'] ?? '').toString();
}
