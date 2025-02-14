import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '/utils/frame_channel.dart';
import '/utils/fingertip_overlay.dart';
import 'package:flutter/services.dart'; // For MethodChannel
import 'dart:math' as math;




class CameraOpenCVPage extends StatefulWidget {
  @override
  _CameraOpenCVPageState createState() => _CameraOpenCVPageState();
}

class _CameraOpenCVPageState extends State<CameraOpenCVPage> {

  CameraController? _controller;
  late List<CameraDescription> _cameras;
  late CameraDescription _camera;
  bool _isCameraInitialized = false;

  Uint8List? _processedFrame;
  final GlobalKey<FingertipOverlayState> _overlayKey = GlobalKey();

  void addNewPoint(double x, double y) {
    if (x < 0.0 && x > -2.0 && y < 0.0 && y > -2.0){
      _overlayKey.currentState?.addPoint(Offset.infinite);
    }else {
      x = x * 0.5 - 10;
      y = y * 0.5 - 50;
      _overlayKey.currentState?.addPoint(Offset(x, y));
    }
  }

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
      imageFormatGroup: ImageFormatGroup.yuv420, // Try to reduce processing load
    );
    await _controller!.initialize();
    if(!mounted) return;
    setState(() {
      _isCameraInitialized = true;
    });

    // Start the image stream
    int frameCounter = 0;
    _controller!.startImageStream((CameraImage image) async {
      frameCounter++;
      if (frameCounter % 1 == 0){
        final result = await onCameraFrame(image);
        final processedFrame = result["frameBytes"] ?? Uint8List(0);
        double cx = (result["cx"] as double?) ?? -1.0;
        double cy = (result["cy"] as double?) ?? -1.0;
        if (processedFrame != null && mounted){
          debugPrint('Coordinates: x=$cx, y=$cy');
          setState(() {
            _processedFrame = processedFrame;
            addNewPoint(cx, cy);
          });
        }
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
    final size = MediaQuery.of(context).size;
    if (!_isCameraInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera Feed with OpenCV Processing'),
      ),
      body: Stack(
        children: [
          SizedBox(
            height: size.height,
            width: size.width,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: 100,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(math.pi),
                  child: CameraPreview(_controller!),
                ),
              ),
            ),
          ), //CameraPreview
          FingertipOverlay(key: _overlayKey),
        ]
      )
      // Uncomment if debugging
      // body: _processedFrame != null
      //     ? Image.memory(_processedFrame!) // Display the processed frame
      //     : CameraPreview(_controller!),
    );
  }
}