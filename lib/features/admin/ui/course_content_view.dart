import 'package:flutter/material.dart';

class CourseContentView extends StatefulWidget {
  const CourseContentView({
    super.key,
    required this.email,
  });

  final String email;

  @override
  State<CourseContentView> createState() => _CourseContentViewState();
}

class _CourseContentViewState extends State<CourseContentView> {
  bool isEditMode = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Course Content",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          // Top row: toggle on left, create folder button on right
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
                onPressed: () {
                  // functionality will be added later
                },
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

          const SizedBox(height: 32),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  "Empty",
                  style: TextStyle(
                    fontSize: 40,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}