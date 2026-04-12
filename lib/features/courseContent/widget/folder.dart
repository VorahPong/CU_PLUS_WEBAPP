import 'content_item.dart';

class Folder {
  String title;
  bool isExpanded;
  List<Folder> children;
  List<ContentItem> contents;

  Folder({
    required this.title,
    this.isExpanded = false,
    List<Folder>? children,
    List<ContentItem>? contents,
  })  : children = children ?? [],
        contents = contents ?? [];
}