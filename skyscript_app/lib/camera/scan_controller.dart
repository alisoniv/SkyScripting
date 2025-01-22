import 'package:camera/camera.dart';
import 'package:get/state_manager.dart';
import 'dart:developer';
import 'package:flutter/foundation.dart';

class ScanController extends GetxController {
  final RxBool _isInitialized = RxBool(false);
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;

  bool get isInitialized => _isInitialized.value;
  CameraController get cameraController => _cameraController;

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      debugPrint("\nCameras detected\n");
    }
    _cameraController = CameraController(_cameras[0], ResolutionPreset.low);

    if (!isInitialized) {
      _cameraController.initialize().then((_) {
        debugPrint("\nInitializing Camera\n");
        _isInitialized.value = true;
      }).catchError((Object e) {
        if (e is CameraException) {
          debugPrint(e.code);
        }
      });
    } else {
      debugPrint("\nCamera already initialized\n");
    }
  }

  // @override
  // void onClose() {
  //   if (_isInitialized.value) {
  //     _cameraController.dispose();
  //     debugPrint("\nCamera disposed\n");
  //     _isInitialized.value = false;
  //   }
  //   super.onClose();
  // }
  
  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  void onInit() {
    _initCamera();
    super.onInit();
  }
}
