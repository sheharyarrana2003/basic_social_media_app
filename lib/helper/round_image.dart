import 'dart:typed_data';

import 'package:flutter/material.dart';

class AppRoundImage extends StatelessWidget {
  final ImageProvider provider;
  final double height;
  final double width;

  const AppRoundImage(this.provider,
      {super.key, required this.height, required this.width});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Image(
        image: provider,
        height: height,
        width: width,
        fit: BoxFit.cover,
      ),
    );
  }

  factory AppRoundImage.uri(String uri,
      {required double height, required double width}) {
    return AppRoundImage(
      NetworkImage(uri),
      height: height,
      width: width,
    );
  }

  factory AppRoundImage.memory(Uint8List data,
      {required double height, required double width}) {
    return AppRoundImage(
      MemoryImage(data),
      height: height,
      width: width,
    );
  }
}
