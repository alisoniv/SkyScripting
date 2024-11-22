import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FilesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Files Page'),
      ),
      body: Column(
        children: [
          const Text('Welcome to the Files Page'),
          ElevatedButton(
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles(); //Open Device UI to pick file
              if (result == null) return;

              final file = result.files.first;
              // openFile(file);
            }, 
            child: const Text('Pick File'),
          ),
        ]
      ),
    );
  }
}