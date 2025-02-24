import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Center(
        child: const Text(
            'The Sky is Your Canvas',
            style: TextStyle (
              fontSize: 40,
              fontWeight: FontWeight.bold,
            )
        ),
      ),
    );
  }
}