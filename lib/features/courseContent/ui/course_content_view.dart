import 'package:flutter/material.dart';
import '../widget/folder.dart';

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

  List<Folder> folders = [
  Folder(
    title: "1st Year PLUS Materials",
    children: [
      Folder(title: "Semester 1"),
      Folder(title: "Semester 2"),
    ],
  ),
  Folder(title: "2nd Year PLUS Materials"),
  Folder(title: "3rd & 4th Year PLUS Materials"),
  Folder(title: "Volunteer Opportunities"),
  Folder(title: "Career Profiling Tools"),
  ];

  Widget _buildFolderTile(Folder folder, int index) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              folder.title,
              style: const TextStyle(fontSize: 16),
            ),

            Row(
              children: [
                if (isEditMode)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () {},
                  ),

                if (isEditMode)
                  OutlinedButton.icon(
                    onPressed: () {
                      // later: add subfolder/content
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Add Content"),
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

                if (isEditMode)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        folders.removeAt(index);
                      });
                    },
                  ),
              ],
            ),
          ],
        ),

        // Expanded content (subfolders)
        if (folder.isExpanded)
          Column(
            children: folder.children.map((child) {
              return ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(child.title),
              );
            }).toList(),
          ),
      ],
    ),
  );
}

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
                  setState(() {
                    folders.add(
                      Folder(title: "New Folder"),
                    );
                  });
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
              child: ListView.builder(
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    return _buildFolderTile(folder, index);
                  },
              ),
            ),
          ),
        ],
      ),
    );
  }
}