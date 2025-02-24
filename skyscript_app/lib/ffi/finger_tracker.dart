import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import '/utils/processed_frame.dart';

/// Load the native library
final DynamicLibrary _nativeLib = Platform.isAndroid
    ? DynamicLibrary.open("libfinger_tracker.so")
    : DynamicLibrary.process();

/// Define FFI function signature
typedef ProcessYUVNative = Void Function(
    Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>,
    Int32, Int32, Int32, Int32, Int32,
    Pointer<Pointer<Uint8>>, Pointer<Int32>, // Processed Frame
    Pointer<Int32>, Pointer<Int32>, // X and Y
    );

typedef ProcessYUVDart = void Function(
    Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>,
    int, int, int, int, int,
    Pointer<Pointer<Uint8>>, Pointer<Int32>,
    Pointer<Int32>, Pointer<Int32>);

/// Get the function from the library
final ProcessYUVDart detectFingertipOrange = _nativeLib
    .lookup<NativeFunction<ProcessYUVNative>>('detectFingertipOrange')
    .asFunction();

/// Free allocated memory in C++
typedef FreeImageNative = Void Function(Pointer<Uint8>);
typedef FreeImageDart = void Function(Pointer<Uint8>);

final FreeImageDart freeImageMemory = _nativeLib
    .lookup<NativeFunction<FreeImageNative>>('freeImageMemory')
    .asFunction();

/// Converts YUV data to grayscale and returns a Uint8List
ProcessedFrame detectFingertip({
  required Uint8List yPlane,
  required Uint8List uPlane,
  required Uint8List vPlane,
  required int width,
  required int height,
  required int rowStride,
  required int pixelStride,
  required int isSamsungTablet,
}) {
  final Pointer<Uint8> yPtr = malloc.allocate<Uint8>(yPlane.length);
  final Pointer<Uint8> uPtr = malloc.allocate<Uint8>(uPlane.length);
  final Pointer<Uint8> vPtr = malloc.allocate<Uint8>(vPlane.length);
  // final Pointer<Uint8> outputPtr = malloc.allocate<Uint8>(width * height);
  final Pointer<Pointer<Uint8>> outputPtr = malloc.allocate<Pointer<Uint8>>(sizeOf<Pointer<Uint8>>());
  outputPtr.value = nullptr;  // Initialize to null
  final Pointer<Int32> outputSizePtr = malloc.allocate<Int32>(sizeOf<Int32>());
  final Pointer<Int32> cxPtr = malloc.allocate<Int32>(sizeOf<Int32>());
  final Pointer<Int32> cyPtr = malloc.allocate<Int32>(sizeOf<Int32>());

  try {
    // Copy data to native memory
    yPtr.asTypedList(yPlane.length).setAll(0, yPlane);
    uPtr.asTypedList(uPlane.length).setAll(0, uPlane);
    vPtr.asTypedList(vPlane.length).setAll(0, vPlane);

    // Call the native function
    detectFingertipOrange(
      yPtr, uPtr, vPtr,
      width, height, rowStride, pixelStride, isSamsungTablet,
      outputPtr, outputSizePtr, cxPtr, cyPtr,
    );

    // Get the output size
    int outputSize = outputSizePtr.value;

    // Extract and package relevant values
    Uint8List debugImage = outputPtr.value.asTypedList(outputSize);
    int cx = cxPtr.value;
    int cy = cyPtr.value;

    ProcessedFrame frame = ProcessedFrame(debugImage, cx, cy);

    if (outputPtr.value != nullptr) {
      freeImageMemory(outputPtr.value);
      outputPtr.value = nullptr;  // Prevent double free
    }

    return frame;
  } finally {
    // Free allocated memory
    malloc.free(yPtr);
    malloc.free(uPtr);
    malloc.free(vPtr);
    malloc.free(outputPtr);
    malloc.free(outputSizePtr);
    malloc.free(cxPtr);
    malloc.free(cyPtr);
  }
}
