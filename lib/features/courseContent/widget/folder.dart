class Folder {
  String title;
  bool isExpanded;
  List<Folder> children;
  List<Map<String, dynamic>> attachedForms;

  Folder({
    required this.title,
    this.isExpanded = false,
    List<Folder>? children,
    List<Map<String, dynamic>>? attachedForms,
  })  : children = children ?? [],
        attachedForms = attachedForms ?? [];
}