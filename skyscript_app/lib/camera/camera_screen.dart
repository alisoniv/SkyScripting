import 'package:flutter/material.dart';
import 'package:skyscriptingapp/camera/camera_viewer.dart';


class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: const [
        CameraViewer(),
      ],
    );
  }
}