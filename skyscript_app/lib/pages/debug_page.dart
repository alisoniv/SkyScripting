import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/utils/fingertip_overlay.dart'; // Adjust the path based on where your provider is defined

// Page to display the generated air-drawing (Fed to the model, not meant to be seen)
class DebugPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final imageProvider = context.watch<ImageProviderNotifier>();

    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 200,
          height: 200,
          child: imageProvider.image != null
              ? Image.memory(imageProvider.image!)
              : const Text("No image yet"),
        ),
      ),
    );
  }
}
