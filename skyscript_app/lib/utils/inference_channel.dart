import 'package:flutter/services.dart'; // For MethodChannel
import 'package:flutter/material.dart';

// Method Channel Class to send list of points for letter inference to Native Kotlin-side
class InferenceChannel {
  static const MethodChannel _inferenceChannel = MethodChannel('camera_frame_channel');

  Future<Map<String, dynamic>> getTop3Letters(List<Offset> points) async {
    try {
      List<List<double>> pointsKotlin = points.map((p) => [p.dx, p.dy]).toList();
      final result = await _inferenceChannel.invokeMethod('inferLetter', pointsKotlin);
      if (result is Map){
        return result.cast<String, dynamic>();
      }else{ return result; }
    } catch (e) {
      debugPrint("Error with inference: $e");
      return {};
    }
  }

}