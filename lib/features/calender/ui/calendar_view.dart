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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 620;
        final daySpacing = isCompact ? 3.0 : 6.0;
        final dayPadding = isCompact ? 5.0 : 7.0;

        return Container(
          padding: EdgeInsets.all(isCompact ? 10 : 14),
          constraints: const BoxConstraints(minWidth: 0),
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    _CalendarNavButton(
                      icon: Icons.chevron_left,
                      onTap: _goToPreviousMonth,
                    ),
                    Expanded(
                      child: Text(
                        _monthLabel(_focusedMonth),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isCompact ? 18 : 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    _CalendarNavButton(
                      icon: Icons.chevron_right,
                      onTap: _goToNextMonth,
                    ),
                  ],
                ),
                SizedBox(height: isCompact ? 8 : 10),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: isCompact ? 11 : 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: isCompact ? 4 : 6),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: days.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: isCompact ? 0.68 : 0.9,
                    crossAxisSpacing: daySpacing,
                    mainAxisSpacing: daySpacing,
                  ),
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final isCurrentMonth = _isSameMonth(day, _focusedMonth);
                    final isToday = _isSameDay(day, _today);
                    final dayForms = _formsForDay(day);

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.all(dayPadding),
                        decoration: BoxDecoration(
                          color: isToday
                              ? Colors.black
                              : isCurrentMonth
                              ? Colors.white
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isToday
                                ? Colors.black
                                : Colors.grey.shade300,
                            width: isToday ? 1.5 : 1,
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, cellConstraints) {
                            final maxVisibleForms = isCompact ? 1 : 1;
                            final hasMore = dayForms.length > maxVisibleForms;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${day.day}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: isCompact ? 12 : 14,
                                    color: isToday
                                        ? Colors.white
                                        : isCurrentMonth
                                        ? Colors.black87
                                        : Colors.grey.shade500,
                                  ),
                                ),
                                SizedBox(height: isCompact ? 3 : 5),
                                if (dayForms.isNotEmpty)
                                  ...dayForms.take(maxVisibleForms).map((form) {
                                    return Flexible(
                                      fit: FlexFit.loose,
                                      child: Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(
                                          bottom: 3,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isCompact ? 4 : 6,
                                          vertical: isCompact ? 2 : 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isToday
                                              ? Colors.white.withOpacity(0.14)
                                              : const Color(0xFFFFF4CC),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: isToday
                                                ? Colors.white24
                                                : const Color(0xFFFFD971),
                                          ),
                                        ),
                                        child: Text(
                                          (form['title'] ?? 'Untitled Form')
                                              .toString(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: isCompact ? 9 : 10,
                                            color: isToday
                                                ? Colors.white
                                                : const Color(0xFF8A5A00),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                if (hasMore)
                                  Text(
                                    '+${dayForms.length - maxVisibleForms} more',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: isCompact ? 8 : 9,
                                      color: isToday
                                          ? Colors.white70
                                          : Colors.grey.shade700,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUpcomingList() {
    final isAdmin = widget.isAdmin || context.auth.isAdmin;
    final monthlyForms = _formsForFocusedMonth();

    return Container(
      padding: const EdgeInsets.all(18),
      constraints: const BoxConstraints(minWidth: 0),
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
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4CC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: Color(0xFFB77900),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tasks This Month',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Forms with upcoming due dates',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (monthlyForms.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                'No forms with due dates this month.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            )
          else
            ...monthlyForms.map((form) {
              final formId = form['id']?.toString();
              final dueDate = _parseDueDate(form);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
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
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 360;

                          final iconBox = Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF4CC),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.description_outlined,
                              color: Color(0xFFB77900),
                            ),
                          );

                          final textContent = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (form['title'] ?? 'Untitled Form').toString(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                              ),
                              if (isAdmin) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Year: ${form['year']?.toString().isNotEmpty == true ? form['year'] : 'All Years'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          );

                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    iconBox,
                                    const Spacer(),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                textContent,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              iconBox,
                              const SizedBox(width: 14),
                              Expanded(child: textContent),
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.black54,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
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
      padding: EdgeInsets.all(
        MediaQuery.of(context).size.width < 600 ? 14 : 24,
      ),
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
                    onPressed: _loadCalendarItems,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Container(
                    //   width: 42,
                    //   height: 42,
                    //   decoration: BoxDecoration(
                    //     color: const Color(0xFFFFF4CC),
                    //     borderRadius: BorderRadius.circular(10),
                    //   ),
                    //   child: const Icon(
                    //     Icons.calendar_month_outlined,
                    //     color: Color(0xFFB77900),
                    //   ),
                    // ),
                    const SizedBox(width: 0),
                    Expanded(
                      child: Text(
                        'Calendar',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 24,
                          // fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey.shade300, thickness: 1),
                const SizedBox(height: 20),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 1000;

                      if (isWide) {
                        return SingleChildScrollView(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: _buildCalendarGrid()),
                              const SizedBox(width: 20),
                              Expanded(flex: 2, child: _buildUpcomingList()),
                            ],
                          ),
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

class _CalendarNavButton extends StatelessWidget {
  const _CalendarNavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Icon(icon, color: Colors.black),
        ),
      ),
    );
  }
}
