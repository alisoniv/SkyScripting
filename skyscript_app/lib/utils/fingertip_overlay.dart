import 'package:flutter/material.dart';
import '/utils/inference_channel.dart';
import 'dart:typed_data'; //For Uint8List
import 'package:provider/provider.dart';

// Used to do updates to debug_page.dart
class ImageProviderNotifier extends ChangeNotifier {
  Uint8List? _image;
  Uint8List? get image => _image;
  void setImage(Uint8List newImage) {
    _image = newImage;
    notifyListeners();
  }
}

class FingertipOverlay extends StatefulWidget {
  // final int isTablet = 0;

  // const FingertipOverlay({Key? key, required this.isTablet}) : super(key: key);
  const FingertipOverlay({Key? key}) : super(key: key);

  @override
  FingertipOverlayState createState() => FingertipOverlayState();
}

class FingertipOverlayState extends State<FingertipOverlay>{
  List<Offset> points = [];
  List<Offset> calibPoints = [];

  // Draw Point on Screen - if Valid
  void addPoint(Offset newPoint) {
    if (!mounted || newPoint.isInfinite) return;
    setState(() {
      points.add(newPoint);
    });
  }

  // Calibrate positioning of bounding boxes
  void calibratePoint(Offset newPoint) {
    if (!mounted || newPoint.isInfinite) return;
    setState(() {
      calibPoints.add(newPoint);
    });
  }

  // Wipe Points from Screen
  void clearPoints(){
    if (!mounted) return;
    setState(() {
      points.clear();
      calibPoints.clear();
    });
  }

  // Send points to Native-Kotlin side to infer letter
  Future<String> inferLetter() async{
    /*
    Input - Nothing
    Output - Top 3 Letters in confidence after inference
    */

    // Method Channel to communicate with Kotlin side
    InferenceChannel channel = InferenceChannel();


    if(points.isEmpty){ //Shouldn't happen, but just in case
      debugPrint("Error: no points?");
      return "0";
    }

    // Perform Inference using EMNIST-Letters Model
    final outputs = await channel.getTop3Letters(points);
    int maxIndex = outputs["index"] - 1;
    //List<String> top3 = (outputs["top3"] as List).cast<String>();
    //Uint8List letterImage = outputs["byteArray"] as Uint8List? ?? Uint8List(0);

    //Send Image to debug_page.dart
    //if (context.mounted) context.read<ImageProviderNotifier>().setImage(letterImage);

    //Clear Drawing Screen
    clearPoints();

    return String.fromCharCode(65 + maxIndex);
  }

  @override
  Widget build(BuildContext context) {
    // Handles Drawing Overlay for Finger-Tracer
    return GestureDetector(
      child: CustomPaint(
        // painter: FingerPainter(points, widget.isTablet),
        painter: FingerPainter(points, calibPoints),
        size: Size.infinite,
      ),
    );
  }
}

// Interface with Painter Class to Draw Dots over Fingertip
class FingerPainter extends CustomPainter {
  List<Offset> points = [];
  List<Offset> calibPoints = [];
  // final int isTablet;

  // FingerPainter(this.points, this.isTablet);
  FingerPainter(this.points, this.calibPoints);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw circles at each point
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    double radius = 15.0;
    for (var point in points) {
      if (point != Offset.infinite) {
        canvas.drawCircle(point, radius, paint); // Adjust radius as needed
      }
    }

    //Draw Calibration Points

    final calibPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;


    for(var calib in calibPoints){
      if (calib != Offset.infinite) {
        canvas.drawCircle(calib, radius, calibPaint); // Adjust radius as needed
      }
    }
  }

  @override
  bool shouldRepaint(FingerPainter oldDelegate) => true;
}