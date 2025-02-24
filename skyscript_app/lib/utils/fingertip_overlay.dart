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
  const FingertipOverlay({Key? key}) : super(key: key);

  @override
  FingertipOverlayState createState() => FingertipOverlayState();
}

class FingertipOverlayState extends State<FingertipOverlay>{
  List<Offset> points = [];

  // Draw Point on Screen - if Valid
  void addPoint(Offset newPoint) {
    if (!mounted || newPoint.isInfinite) return;
    setState(() {
      points.add(newPoint);
    });
  }

  // Wipe Points from Screen
  void clearPoints(){
    if (!mounted) return;
    setState(() {
      points.clear();
    });
  }

  // Send points to Native-Kotlin side to infer letter
  Future<List<String>> inferLetter() async{
    /*
    Input - Nothing
    Output - Top 3 Letters in confidence after inference
    */

    // Method Channel to communicate with Kotlin side
    InferenceChannel channel = InferenceChannel();

    if(points.isEmpty){ //Shouldn't happen, but just in case
      debugPrint("Error: no points?");
      return ["X", "Y", "Z"];
    }

    // Perform Inference using EMNIST-Letters Model
    final outputs = await channel.getTop3Letters(points);
    List<String> top3 = (outputs["top3"] as List).cast<String>();
    Uint8List letterImage = outputs["byteArray"] as Uint8List? ?? Uint8List(0);

    //Send Image to debug_page.dart
    if (context.mounted) context.read<ImageProviderNotifier>().setImage(letterImage);

    //Clear Drawing Screen
    clearPoints();

    return top3;
  }

  @override
  Widget build(BuildContext context) {
    // Handles Drawing Overlay for Finger-Tracer
    return GestureDetector(
      child: CustomPaint(
        painter: FingerPainter(points),
        size: Size.infinite,
      ),
    );
  }
}

// Interface with Painter Class to Draw Dots over Fingertip
class FingerPainter extends CustomPainter {
  List<Offset> points = [];

  FingerPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Draw circles at each point
    for (var point in points) {
      if (point != Offset.infinite) {
        canvas.drawCircle(point, 20.0, paint); // Adjust radius as needed
      }
    }
  }

  @override
  bool shouldRepaint(FingerPainter oldDelegate) => true;
}