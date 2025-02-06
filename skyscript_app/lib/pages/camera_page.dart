import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:math' as math;

late List<CameraDescription> _cameras;

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _controller;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    initCamera();
    super.initState();
  }

  Future<void> initCamera() async { //Initialize Camera (Async func so loading screen can provide feedback to user)
    _cameras = await availableCameras(); //await forces function to wait before continuing (semi-synchronous)
    _controller = CameraController(_cameras[0], ResolutionPreset.low); //Choose camera and set resolution cam[0] for emulator cam[1] for device
    try {
      await _controller.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (!_isCameraInitialized) { //Show loading circle while camera inactive
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()), 
      );
    } else { //Show Camera Feed
      return SizedBox(
        height: size.height,
        width: size.width,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: 100,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(math.pi),
              child: CameraPreview(_controller),
            ),
          ),
        ),
      );
    }
  }
}
