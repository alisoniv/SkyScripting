import 'package:flutter/material.dart';

class FingertipOverlay extends StatefulWidget {
  const FingertipOverlay({Key? key}) : super(key: key);

  @override
  FingertipOverlayState createState() => FingertipOverlayState();
}

class FingertipOverlayState extends State<FingertipOverlay>{
  List<Offset> points = [];

  void addPoint(Offset newPoint) {
    if (!mounted) return;
    setState(() {
      points.add(newPoint);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: CustomPaint(
        painter: FingerPainter(points),
        size: Size.infinite,
      ),
    );
  }
}

class FingerPainter extends CustomPainter {
  List<Offset> points = [];

  FingerPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // for (int i = 0; i < points.length - 1; i++) {
    //   if (points[i] != Offset.infinite && points[i + 1] != Offset.infinite) {
    //     canvas.drawLine(points[i], points[i + 1], paint);
    //   }
    // }

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