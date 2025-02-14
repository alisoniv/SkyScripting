import 'package:flutter/services.dart'; // For MethodChannel
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraFrameProcessor {
  static const MethodChannel _frameChannel = MethodChannel('camera_frame_channel');

  // Process the captured camera frame and send it to Android side for OpenCV processing
  Future<Map<String, dynamic>> sendCameraFrame(Map<String, dynamic> args) async {
    try {
      final result = await _frameChannel.invokeMethod('processFrame', args);
      if (result is Map){
        return result.cast<String, dynamic>();
      }
      return result;
    } catch (e) {
      debugPrint("Error sending frame: $e");
      return {};
    }
  }
}

Future<Map<String, dynamic>> onCameraFrame(CameraImage image) async {
  // Convert the camera frame to a Uint8List (raw YUV or RGB)
  final Map<String, dynamic> args = {
    'yPlane': image.planes[0].bytes, // Y (Luminance)
    'uPlane': image.planes[1].bytes, // U (Chroma Blue)
    'vPlane': image.planes[2].bytes, // V (Chroma Red)
    'imageWidth': image.width,
    'imageHeight': image.height,
    'rowStride': image.planes[0].bytesPerRow,
    'pixelStride': image.planes[1].bytesPerPixel, // U and V share the same pixel stride
  };

  final processor = CameraFrameProcessor();
  return await processor.sendCameraFrame(args);
}