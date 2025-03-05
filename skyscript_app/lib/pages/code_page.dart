import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '/utils/frame_channel.dart';
import '/utils/fingertip_overlay.dart';
import 'dart:math' as math;
import '/ffi/finger_tracker.dart';
import 'dart:typed_data';
import '/utils/processed_frame.dart';

class CodePage extends StatefulWidget {
  @override
  _CodePageState createState() => _CodePageState();
}

class _CodePageState extends State<CodePage> {
  CameraController? _controller;
  late List<CameraDescription> _cameras;
  late CameraDescription _camera;
  bool _isCameraInitialized = false;
  int _isSamsungTablet = 0;
  double _deviceWidth = -1.0;
  double _deviceHeight = -1.0;
  int _widthOffset = 0; //Set during build func
  int _heightOffset = 0; //Set during build func
  int frame_counter = 0;
  String currentText = "HELLO: ";
  bool sim = false;
  bool debug = false; //Set to true to calibrate bounding boxes for clear and infer (displays blue dots)

  Uint8List? _processedFrame;



  // Communicate with Fingertip Drawing Overlay
  final GlobalKey<FingertipOverlayState> _overlayKey = GlobalKey();

  // Artificial Timers To Determine Action
  int deleteCount = 0;
  int inferCount = 0;
  bool cooldown = false;

  // Add point given (x,y) coords from detector
  void addNewPoint(double x, double y) async {
    // Prevent Double Action
    if (cooldown) {
      if (y < 210) { cooldown = false; }
      return;
    }
    // Handle Overlay Boundaries for Samsung Tablet and other devices
    if (_isSamsungTablet == 1 && (x < -40 || x > 190 || y < 25) ){ //Borders for Tablet
      _overlayKey.currentState?.addPoint(Offset.infinite);
      deleteCount = 0;
      inferCount = 0;
    } else if (x < -90.0 && y < -90.0){ //Default Boundaries
      _overlayKey.currentState?.addPoint(Offset.infinite);
      deleteCount = 0;
      inferCount = 0;
    }else {
      if(_deviceWidth < 0 || _deviceHeight < 0){return;}

      double xScale = _deviceWidth / 240;
      double yScale = _deviceHeight / 320;
      // Display points according to device scale
      x = x * xScale + _widthOffset;
      y = y * yScale + _heightOffset;

      /*
      Action Decision Making State Machine Thing
      Handles Deletion and Inference So Far
       */
      //Set button boxes
      double deleteYThresh = 250.0 * yScale + _heightOffset;
      double deleteXThresh = 110.0 * xScale + _widthOffset;
      double inferXThresh = 130.0 * xScale + _widthOffset;

      if (y > deleteYThresh){
        if (x < deleteXThresh){
          deleteCount += 1;
          if(debug) _overlayKey.currentState?.calibratePoint(Offset(deleteXThresh, deleteYThresh));
          if (deleteCount >= 20){
            _overlayKey.currentState?.clearPoints();
            cooldown=true;
            deleteCount=0;
          }
        }else if(x > inferXThresh){
          inferCount += 1;
          if(debug) _overlayKey.currentState?.calibratePoint(Offset(inferXThresh, deleteYThresh));
          if (inferCount >= 20){
            List<String> top3 = await _overlayKey.currentState?.inferLetter() ?? ["ERR", "ERR2", "ERR3"];
            cooldown=true;
            inferCount=0;
            currentText += top3[0];
          }
        }
        return;
      }else{
        deleteCount = 0;
        inferCount = 0;
      }
      // Add Point to Overlay
      _overlayKey.currentState?.addPoint(Offset(x, y));

      // print("X: ${x}");
      // print("Y: ${y}");
      // print("w_off: ${_widthOffset}");
      // print("h_off: ${_heightOffset}");


    }
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras.length > 1) {
      _camera = _cameras[1];
    }else {
      _camera = _cameras.first; // Select first camera (back/front)
    }

    // Camera Parameters (Only Tested on Low Resolution so far)
    _controller = CameraController(
      _camera,
      ResolutionPreset.low,
      enableAudio: false,
    );

    await _controller!.initialize();
    await _controller!.lockCaptureOrientation();

    if(!mounted) return;
    setState(() {
      _isCameraInitialized = true;
    });

    // Start the image stream
    bool _isProcessing = false;
    int frameNum = 0;

    // Send Frames to Dart FFI (C++ side) for processing
    _controller!.startImageStream((CameraImage image) async {
      frameNum += 1;

      // Processes every second frame (C++ is too fast for flutter in simulator)
      if (frameNum % 2 != 0 && sim){return;}

      // Handle processing, ensure one-at-a-time processing
      if (_isProcessing || image == null) return; // Skip frame if processing is ongoing
      _isProcessing = true;
      processFrame(image);
      _isProcessing = false;
    });
  }

  // Call C++ FFI function
  // Receives Image-Post-Process (for debugging) and X,Y coords of orange dot / fingertip
  void processFrame(CameraImage image) {
    // print("Format: ${image.format.group}");
    // print("Planes: ${image.planes.length}");
    // print("rowStride: ${image.planes[0].bytesPerRow}");
    // print("pixelStride: ${image.planes[1].bytesPerPixel}");
    // print("Width: ${image.width}");
    // print("Height: ${image.height}");

    if (image.planes.length < 3) {
      debugPrint("Error: CameraImage does not contain all YUV planes!");
      return;
    }
    if (image.planes[0].bytes.isEmpty ||
        image.planes[1].bytes.isEmpty ||
        image.planes[2].bytes.isEmpty) {
      debugPrint("Error: One or more YUV planes are empty!");
      return;
    }

    // Flutter image (on Android) usually in YUV Format, need to pass planes separately
    final Map<String, dynamic> args = {
      'yPlane': image.planes[0].bytes, // Y (Luminance)
      'uPlane': image.planes[1].bytes, // U (Chroma Blue)
      'vPlane': image.planes[2].bytes, // V (Chroma Red)
      'imageWidth': image.width,
      'imageHeight': image.height,
      'rowStride': image.planes[0].bytesPerRow,
      'pixelStride': image.planes[1].bytesPerPixel ?? 1,
      'isSamsungTablet': _isSamsungTablet,
    };

    ProcessedFrame result = detectFingertip(
      yPlane: args['yPlane'],
      uPlane: args['uPlane'],
      vPlane: args['vPlane'],
      width: args['imageWidth'],
      height: args['imageHeight'],
      rowStride: args['rowStride'],
      pixelStride: args['pixelStride'],
      isSamsungTablet: args['isSamsungTablet'],
    );
    Uint8List processed = result.frame;
    double cx = result.cx.toDouble();
    double cy = result.cy.toDouble();

    if (processed == null || processed.isEmpty) {
      debugPrint("Invalid image data: null or empty");
      return;
    }

    if(!mounted) return;
    setState(() {
      /*
      Copy Frame Data Because C++ is so fast that it clears the image buffer before
      Flutter even tries to render the image
       */
      _processedFrame = Uint8List.fromList(processed);
      // Add Point to Overlay
      addNewPoint(cx, cy);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double short = size.shortestSide;

    _deviceWidth = size.width;
    _deviceHeight = size.height;
    // print("Widths: ${_deviceWidth}");
    // print("Heights: ${_deviceHeight}");

    if (size.width > 600.0){ //For Tablet A9+
      _isSamsungTablet = 1;
      _widthOffset = 0;
      _heightOffset = -100;
    }else{                   //EDIT these for Phone S23
      _isSamsungTablet = 0;
      _widthOffset = 0;
      _heightOffset = 0;
    }

    if (!_isCameraInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
        appBar: AppBar(
          title: Text('Camera Feed with OpenCV Processing'),
        ),
        // If debugging uncomment this body and comment out the other body
        // This body shows white for detecting orange and black for no detecting orange
        // See finger_tracker.cpp for more info
        // body: _processedFrame != null
        //     ? Image.memory(_processedFrame!) // Display the processed frame
        //     : CameraPreview(_controller!),

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
                      transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0), // Flip horizontally
                      child: CameraPreview(_controller!),
                    )
                  ),
                ),
              ), //CameraPreview

              // Finger Trace Display
              // FingertipOverlay(key: _overlayKey, isTablet: _isSamsungTablet),
              FingertipOverlay(key: _overlayKey),

              // Air-Traced Text Display
              TextField(
                controller: TextEditingController(text: currentText),
                readOnly: true, // Prevents keyboard input
                enableInteractiveSelection: false, // Disables text selection
                decoration: InputDecoration(
                  border: OutlineInputBorder(), // Optional border
                  contentPadding: EdgeInsets.all(12),
                ),
              ),

              // Delete Box
              Positioned(
                left: size.width * 0, // Adjust position
                top: size.height * 0.7, // Adjust position
                child: Stack(
                  alignment: Alignment.center, // Center items inside the stack
                  children: [
                    Container(
                      width: size.width * 0.45, // Adjust size
                      height: size.height * 0.1, // Adjust size
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red.shade400, width: 3), // Red border
                        color: Colors.red.shade400.withOpacity(0.8), // Semi-transparent fill
                      ),
                    ),
                    Icon(
                      Icons.close,
                      color: Colors.white,
                      size: size.height * 0.08,
                    ),
                  ]
                ),
              ),

              // Infer Box
              Positioned(
                left: size.width * 0.55, // Adjust position
                top: size.height * 0.7, // Adjust position
                child: Stack(
                  alignment: Alignment.center, // Center items inside the stack
                  children: [
                    Container(
                      width: size.width * 0.45, // Adjust size
                      height: size.height * 0.1, // Adjust size
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green.shade900, width: 3), // Red border
                        color: Colors.green.shade700.withOpacity(0.8), // Semi-transparent fill
                      ),
                    ),
                    Icon(
                      Icons.check,
                      color: Colors.white,
                      size: size.height * 0.08, // Adjust size relative to height
                    ),
                  ]
                ),
              ),

              // Progress Bar
              // ALL THIS IS NEEDED JUST FOR A PROGRESS BAR BY THE WAY
              // LITERALLY MORE CODE THAN THE IMAGE PROCESSING PART - ISN'T FLUTTER AMAZING?
              Visibility(
                visible: deleteCount > 0 || inferCount > 0, // Hide when progress is 0
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Add padding inside
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withOpacity(0.7)
                        ),
                        child:Text(
                            deleteCount > 0 ? "Clearing..." : inferCount > 0 ? "Processing..." : "Stealing Personal Information ...",
                            style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.red.shade600)
                        ),
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        width: 200,
                        height: 25,
                        child: LinearProgressIndicator(
                          value: deleteCount > 0 ? deleteCount / 20.0 : inferCount > 0 ? inferCount / 20.0 : 0.5,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]
        )





    );
  }
}