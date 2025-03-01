import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;



class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});
  
  @override
  State<DrawingPage> createState() => _MyDrawingPageState();
}

class _MyDrawingPageState extends State<DrawingPage> {
  static const MethodChannel pytorchChannel =
      MethodChannel('com.pytorch_channel');
  var result = ''; // Variable to store model output

  @override
  void initState() {
    super.initState();
    _gettingModelFile().then((void value) => print('File Created Successfuly'));
  }
  String documentsPath = '';
  String prediction = '';

  Future<void> _gettingModelFile() async {
    final Directory directory = await getApplicationDocumentsDirectory();

    setState(() {
      documentsPath = directory.path;
    });
    final String model_path = join(directory.path, 'ocr_letters_scripted.pt');
    final ByteData data = await rootBundle.load('assets/ocr_letters_scripted.pt');
    final List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
   
    if (!File(model_path).existsSync()) {
      await File(model_path).writeAsBytes(bytes);
    }

  }

  Future<void> _getPrediction() async {    
    final ByteData imageData = await rootBundle.load('assets/sample.png');
    try {
      final result =  await pytorchChannel.invokeMethod(
        'predict_image_hanna',
        <String, dynamic>{
          'model_path': '$documentsPath/ocr_letters_scripted.pt',
          'image_data': imageData.buffer
              .asUint8List(imageData.offsetInBytes, imageData.lengthInBytes),
          'data_offset': imageData.offsetInBytes,
          'data_length': imageData.lengthInBytes
        },
      );
      if (result != null) {
        int maxIndex = result["index"];
        double maxValue = result["value"];
        debugPrint("Debugging max_value value: $maxValue");
        debugPrint("Debugging max_index value: $maxIndex");
        setState(() {
          prediction = maxIndex.toString();
        });
      }

    } on PlatformException catch (e) {
      print(e);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawing Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Welcome to the DRAWING Page'),
            Row( 
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: _getPrediction,
                  child: const Text('Predict'),
                ),
                const SizedBox(width: 20),  // Add some spacing between the button and result text
                Text("Value: $prediction"), // Display the model prediction result here
              ],
            ),
          ],
        ),
      ),
    );
  }


}
