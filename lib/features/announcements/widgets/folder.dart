import 'package:flutter/material.dart';

class Folder {
  final String title;
  bool isExpanded;
  List<Folder> children;

  Folder({
    required this.title,
    this.isExpanded = false,
    this.children = const [],
  });
}