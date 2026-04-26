import 'package:flutter/material.dart';

class PageSectionHeader extends StatelessWidget {
  const PageSectionHeader({
    super.key,
    required this.title,
    this.fontSize = 24,
    this.fontWeight = FontWeight.normal,
    this.dividerSpacing = 12,
  });

  final String title;
  final double fontSize;
  final FontWeight fontWeight;
  final double dividerSpacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: Colors.black,
          ),
        ),
        SizedBox(height: dividerSpacing),
        Divider(color: Colors.grey.shade300, thickness: 1),
      ],
    );
  }
}
