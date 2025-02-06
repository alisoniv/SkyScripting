import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '/utils/frame_channel.dart';


class CameraOpenCVPage extends StatefulWidget {
  @override
  _CameraOpenCVPageState createState() => _CameraOpenCVPageState();
}

class _CameraOpenCVPageState extends State<CameraOpenCVPage> {

  CameraController? _controller;
  late List<CameraDescription> _cameras;
  late CameraDescription _camera;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }
  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _camera = _cameras.first; // Select first camera (back/front)

    _controller = CameraController(
      _camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _controller!.initialize();

    // Start the image stream
    _controller!.startImageStream((CameraImage image) {
      onCameraFrame(image);
    });

    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Camera Feed with OpenCV Processing'),
      ),
      body: CameraPreview(_controller!), // Display the camera feed
    );
  }
}