import 'package:flutter/material.dart';

class ZoomableReader extends StatelessWidget {
  const ZoomableReader({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.9,
      maxScale: 2.4,
      panEnabled: false,
      child: child,
    );
  }
}
