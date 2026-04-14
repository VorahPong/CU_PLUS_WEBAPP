import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:cu_plus_webapp/core/network/api_client.dart';
import 'package:cu_plus_webapp/core/extensions/auth_extension.dart';
import 'package:cu_plus_webapp/features/forms/api/forms_api.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key, this.isAdmin = false});

  final bool isAdmin;

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  final DateTime _today = DateTime.now();
  late DateTime _focusedMonth;

  List<Map<String, dynamic>> _formsWithDueDates = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(_today.year, _today.month, 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCalendarItems();
    });
  }

  Future<void> _loadCalendarItems() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = FormsApi(context.read<ApiClient>());
      final forms = (widget.isAdmin || context.authRead.isAdmin)
          ? await api.getAdminForms()
          : await api.getStudentForms();

      final filtered =
          forms
              .whereType<Map<String, dynamic>>()
              .where((form) => form['dueDate'] != null)
              .map<Map<String, dynamic>>(
                (form) => Map<String, dynamic>.from(form),
              )
              .toList()
            ..sort((a, b) {
              final aDate = DateTime.tryParse(a['dueDate'].toString());
              final bDate = DateTime.tryParse(b['dueDate'].toString());
              if (aDate == null && bDate == null) return 0;
              if (aDate == null) return 1;
              if (bDate == null) return -1;
              return aDate.compareTo(bDate);
            });

      if (!mounted) return;

      setState(() {
        _formsWithDueDates = filtered;
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

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  DateTime? _parseDueDate(Map<String, dynamic> form) {
    final raw = form['dueDate'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  List<Map<String, dynamic>> _formsForDay(DateTime day) {
    return _formsWithDueDates.where((form) {
      final dueDate = _parseDueDate(form);
      return dueDate != null && _isSameDay(dueDate, day);
    }).toList();
  }

  List<Map<String, dynamic>> _formsForFocusedMonth() {
    return _formsWithDueDates.where((form) {
      final dueDate = _parseDueDate(form);
      return dueDate != null && _isSameMonth(dueDate, _focusedMonth);
    }).toList();
  }

  List<DateTime> _buildCalendarDays() {
    final firstDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    );

    final startOffset = firstDayOfMonth.weekday % 7; // Sunday=0
    final startDay = firstDayOfMonth.subtract(Duration(days: startOffset));

    final endOffset = 6 - (lastDayOfMonth.weekday % 7);
    final endDay = lastDayOfMonth.add(Duration(days: endOffset));

    final days = <DateTime>[];
    DateTime current = startDay;
    while (!current.isAfter(endDay)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  void _goToPreviousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  String _monthLabel(DateTime date) {
    const monthNames = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[date.month - 1]} ${date.year}';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Widget _buildCalendarGrid() {
    final days = _buildCalendarDays();
    const weekLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _goToPreviousMonth,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  _monthLabel(_focusedMonth),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: _goToNextMonth,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: weekLabels.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 2.4,
            ),
            itemBuilder: (context, index) {
              return Center(
                child: Text(
                  weekLabels[index],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              );
            },
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final day = days[index];
              final isCurrentMonth = _isSameMonth(day, _focusedMonth);
              final isToday = _isSameDay(day, _today);
              final dayForms = _formsForDay(day);

              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isToday
                      ? Colors.blue.shade50
                      : isCurrentMonth
                      ? Colors.white
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isToday ? Colors.blue : Colors.grey.shade300,
                    width: isToday ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isCurrentMonth
                            ? Colors.black87
                            : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (dayForms.isNotEmpty)
                      ...dayForms.take(2).map((form) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (form['title'] ?? 'Untitled Form').toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }),
                    if (dayForms.length > 2)
                      Text(
                        '+${dayForms.length - 2} more',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingList() {
    final isAdmin = widget.isAdmin || context.auth.isAdmin;
    final monthlyForms = _formsForFocusedMonth();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tasks This Month',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (monthlyForms.isEmpty)
            const Text('No forms with due dates this month.')
          else
            ...monthlyForms.map((form) {
              final formId = form['id']?.toString();
              final dueDate = _parseDueDate(form);

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (formId == null) return;
                  if (isAdmin) {
                    context.go('/dashboard/admin/forms/$formId/edit');
                  } else {
                    context.go('/dashboard/student/forms/$formId');
                  }
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.assignment_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (form['title'] ?? 'Untitled Form').toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            if (isAdmin) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Year: ${form['year']?.toString().isNotEmpty == true ? form['year'] : 'All Years'}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              dueDate == null
                                  ? 'No due date'
                                  : 'Due: ${_formatDate(dueDate)}',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.open_in_new, size: 18),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.isAdmin || context.auth.isAdmin;
    return Padding(
      padding: const EdgeInsets.all(24),
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
                    onPressed: _loadCalendarItems,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(
                    isAdmin ? 'Admin Calendar' : 'Calendar',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey.shade300, thickness: 1),
                const SizedBox(height: 20),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 1000;

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildCalendarGrid()),
                            const SizedBox(width: 20),
                            Expanded(flex: 2, child: _buildUpcomingList()),
                          ],
                        );
                      }

                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildCalendarGrid(),
                            const SizedBox(height: 20),
                            _buildUpcomingList(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
