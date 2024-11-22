import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skyscriptingapp/camera/scan_controller.dart';
import 'dart:math' as math;

class CameraViewer extends StatelessWidget{
  const CameraViewer({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GetX<ScanController>(builder: (controller) {
      if (!controller.isInitialized) {
        return Container();
      }
      return SizedBox(
        height: size.height,
        width: size.width,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: 100,
            child: Transform (
              alignment: Alignment.center,
              transform: Matrix4.rotationY(math.pi),
              child:CameraPreview(controller.cameraController),
            ),
          ),
        ),
      );
    });
  }
}