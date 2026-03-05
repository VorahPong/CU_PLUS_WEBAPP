import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ManageStudentsView extends StatefulWidget {
  const ManageStudentsView({super.key, required this.email});

  final String email;

  @override
  State<ManageStudentsView> createState() => _ManageStudentsViewState();
}

class _ManageStudentsViewState extends State<ManageStudentsView> {
  // TODO: fetch students from backend and display in table

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
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? const Color(0xFFFFC425) : Colors.white,
              border: Border.all(
                color: value ? const Color(0xFFFFC425) : Colors.grey.shade400,
                width: 2,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
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

  void _setFilter(VoidCallback fn) {
    setState(fn);
    _filterEntry?.markNeedsBuild();
  }

  // ----------------------
  // Actions overlay
  // ----------------------
  OverlayEntry? _actionEntry;
  LayerLink? _activeActionLink; // which row was clicked

  void _toggleActionOverlay(LayerLink link) {
    if (_actionEntry != null) {
      _hideActionOverlay();
      // if user clicked a different row, open again at new position
      if (_activeActionLink != link) {
        _activeActionLink = link;
        _showActionOverlay();
      }
    } else {
      _activeActionLink = link;
      _showActionOverlay();
    }
  }

  void _showActionOverlay() {
    final link = _activeActionLink;
    if (link == null) return;

    _actionEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideActionOverlay,
                child: const SizedBox(),
              ),
            ),

            CompositedTransformFollower(
              link: link,
              showWhenUnlinked: false,
              offset: const Offset(-120, 36), // 👈 tweak to align under "...".
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 160,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
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
                      _actionItem(
                        icon: Icons.visibility_outlined,
                        label: "View",
                        onTap: () {
                          _hideActionOverlay();
                          // TODO: view action
                        },
                      ),
                      _divider(),
                      _actionItem(
                        icon: Icons.edit_outlined,
                        label: "Edit",
                        onTap: () {
                          _hideActionOverlay();
                          // TODO: edit action
                        },
                      ),
                      _divider(),
                      _actionItem(
                        icon: Icons.delete_outline,
                        label: "Delete",
                        isDanger: true,
                        onTap: () {
                          _hideActionOverlay();
                          // TODO: delete action
                        },
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

    Overlay.of(context).insert(_actionEntry!);
  }

  void _hideActionOverlay() {
    _actionEntry?.remove();
    _actionEntry = null;
    _activeActionLink = null;
  }

  Widget _actionsCell() {
    final link = LayerLink(); // ✅ unique per cell

    return CompositedTransformTarget(
      link: link,
      child: IconButton(
        icon: const Icon(Icons.more_horiz),
        tooltip: "Actions",
        onPressed: () => _toggleActionOverlay(link),
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, thickness: 1, color: Colors.grey.shade200);

  Widget _actionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final color = isDanger ? Colors.red : const Color(0xFF111928);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
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
                  width: 280,
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
                              label: "1st Year",
                              value: _year1,
                              onChanged: (val) =>
                                  _setFilter(() => _year1 = val),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _yearToggle(
                              label: "2nd Year",
                              value: _year2,
                              onChanged: (val) =>
                                  _setFilter(() => _year2 = val),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Divider(color: Colors.grey.shade200, thickness: 1),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: _yearToggle(
                              label: "3rd Year",
                              value: _year3,
                              onChanged: (val) =>
                                  _setFilter(() => _year3 = val),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _yearToggle(
                              label: "4th Year",
                              value: _year4,
                              onChanged: (val) =>
                                  _setFilter(() => _year4 = val),
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
    _hideActionOverlay();
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
                      context.go("/dashboard/admin/students/register");
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

                          // Table
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minWidth: 900,
                                      ),
                                      child: DataTable(
                                        columnSpacing: 40,
                                        dividerThickness: 1,
                                        columns: const [
                                          DataColumn(
                                            label: Text(
                                              "School ID",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              "Name",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              "Email",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              "Year",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              "Actions",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                        rows: [
                                          DataRow(
                                            cells: [
                                              DataCell(Text("2026001")),
                                              DataCell(Text("Jane Smith")),
                                              DataCell(Text("jane@school.edu")),
                                              DataCell(Text("1st Year")),
                                              DataCell(_actionsCell()),
                                            ],
                                          ),
                                          DataRow(
                                            cells: [
                                              DataCell(Text("2026002")),
                                              DataCell(Text("Alex Brown")),
                                              DataCell(Text("alex@school.edu")),
                                              DataCell(Text("2nd Year")),
                                              DataCell(_actionsCell()),
                                            ],
                                          ),
                                        ],
                                      ),
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
