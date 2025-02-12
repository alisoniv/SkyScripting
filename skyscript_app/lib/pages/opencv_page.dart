import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '/utils/frame_channel.dart';
import 'package:flutter/services.dart'; // For MethodChannel



class CameraOpenCVPage extends StatefulWidget {
  @override
  _CameraOpenCVPageState createState() => _CameraOpenCVPageState();
}

class _CameraOpenCVPageState extends State<CameraOpenCVPage> {

  CameraController? _controller;
  late List<CameraDescription> _cameras;
  late CameraDescription _camera;

  Uint8List? _processedFrame;

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
      ResolutionPreset.low,
      enableAudio: false,
    );
    await _controller!.initialize();

    // Start the image stream
    _controller!.startImageStream((CameraImage image) async {
      final processedFrame = await onCameraFrame(image);
      if (processedFrame != null){
        setState(() {_processedFrame = processedFrame;});
      }
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
      body: _processedFrame != null
          ? Image.memory(_processedFrame!) // Display the processed frame
          : CameraPreview(_controller!),
    );
  }
}