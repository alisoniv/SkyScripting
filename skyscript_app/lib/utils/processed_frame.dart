import 'dart:typed_data';

// Class to neatly contain relevant info returned by C++ ffi processing
class ProcessedFrame {
  final Uint8List frame;
  final int cx;
  final int cy;

  ProcessedFrame(this.frame, this.cx, this.cy);
}