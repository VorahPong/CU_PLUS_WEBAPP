import 'package:flutter/material.dart';

class ManageStudentsView extends StatefulWidget {
  const ManageStudentsView({super.key, required this.email});

  final String email;

  @override
  State<ManageStudentsView> createState() => _ManageStudentsViewState();
}

class _ManageStudentsViewState extends State<ManageStudentsView> {
  // Check if role is admin otherwise kick out of this page

  bool _showFilter = false;

  bool _year1 = false;
  bool _year2 = false;
  bool _year3 = false;
  bool _year4 = false;

  Widget _yearToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label)),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  final LayerLink _filterLink = LayerLink();
  OverlayEntry? _filterEntry;

  void _toggleFilterOverlay() {
    if (_filterEntry == null) {
      _showFilterOverlay();
    } else {
      _hideFilterOverlay();
    }
  }

  void _showFilterOverlay() {
    _filterEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Click outside to close
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideFilterOverlay,
                child: const SizedBox(),
              ),
            ),

            // The floating dropdown anchored to the Filter button
            CompositedTransformFollower(
              link: _filterLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 42), // dropdown appears under button
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _yearToggle(
                              label: "Year 1",
                              value: _year1,
                              onChanged: (val) => setState(() => _year1 = val),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _yearToggle(
                              label: "Year 2",
                              value: _year2,
                              onChanged: (val) => setState(() => _year2 = val),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: _yearToggle(
                              label: "Year 3",
                              value: _year3,
                              onChanged: (val) => setState(() => _year3 = val),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _yearToggle(
                              label: "Year 4",
                              value: _year4,
                              onChanged: (val) => setState(() => _year4 = val),
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
        );
      },
    );

    Overlay.of(context).insert(_filterEntry!);
  }

  void _hideFilterOverlay() {
    _filterEntry?.remove();
    _filterEntry = null;
  }

  @override
  void dispose() {
    _hideFilterOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: Text("Manage Students", style: TextStyle(fontSize: 24)),
          ),

          const SizedBox(height: 12),

          Divider(color: Colors.grey.shade300, thickness: 1),

          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Register Button
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to register student page
                    },
                    icon: const Icon(Icons.person_add, color: Colors.black),
                    label: const Text(
                      "Register New Student",
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
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: Colors.grey.shade400, // 👈 outline
                          width: 1,
                        ),
                      ),
                      elevation: 2,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Table Section
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),

                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Search + Filter (placeholder)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Search box
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.3,
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: "Search by name, email, or ID",
                                    prefixIcon: const Icon(Icons.search),
                                    filled: false,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade400,
                                        width: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 26),

                              // Filter button + dropdown
                              CompositedTransformTarget(
                                link: _filterLink,
                                child: OutlinedButton(
                                  onPressed: _toggleFilterOverlay,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        Colors.black87, // ✅ make text visible
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                  child: const Text(
                                    "Filter",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Table (takes full remaining height)
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Container(
                                            width: constraints.maxWidth,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey.shade200,
                                                width: 1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: DataTable(
                                              columnSpacing: 40,
                                              dividerThickness:
                                                  1, // row divider
                                              columns: const [
                                                DataColumn(
                                                  label: Text(
                                                    "School ID",
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    "Name",
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    "Email",
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    "Year",
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    "Actions",
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              rows: const [
                                                DataRow(
                                                  cells: [
                                                    DataCell(Text("2026001")),
                                                    DataCell(
                                                      Text("Jane Smith"),
                                                    ),
                                                    DataCell(
                                                      Text("jane@school.edu"),
                                                    ),
                                                    DataCell(Text("Freshman")),
                                                    DataCell(Text("...")),
                                                  ],
                                                ),
                                                DataRow(
                                                  cells: [
                                                    DataCell(Text("2026002")),
                                                    DataCell(
                                                      Text("Alex Brown"),
                                                    ),
                                                    DataCell(
                                                      Text("alex@school.edu"),
                                                    ),
                                                    DataCell(Text("Sophomore")),
                                                    DataCell(Text("...")),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Pagination (placeholder)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        // TODO: previous page
                                      },
                                      icon: const Icon(Icons.chevron_left),
                                    ),

                                    _PageChip(
                                      label: "1",
                                      isActive: true,
                                      onTap: () {
                                        // TODO: go page 1
                                      },
                                    ),
                                    const SizedBox(width: 8),

                                    _PageChip(
                                      label: "2",
                                      isActive: false,
                                      onTap: () {
                                        // TODO: go page 2
                                      },
                                    ),
                                    const SizedBox(width: 8),

                                    _PageChip(
                                      label: "3",
                                      isActive: false,
                                      onTap: () {
                                        // TODO: go page 3
                                      },
                                    ),

                                    IconButton(
                                      onPressed: () {
                                        // TODO: next page
                                      },
                                      icon: const Icon(Icons.chevron_right),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _PageChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.grey.shade200 : Colors.transparent,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
