import 'package:flutter/material.dart';
// import 'package:python_ffi/python_ffi.dart';

class CodePage extends StatefulWidget {
  @override
  _CodeState createState() => _CodeState();

}
  


class _CodeState extends State<CodePage> {
  String result = '';
  
  // void _initPython() async {
  //   await Python.init();
  //   setState(() {
  //     result = 'Python Initialized';
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawing Page'),
      ),
      body: const Center(
        child: Text('Welcome to the DRAWING Page'),
      ),
    );
  }
}