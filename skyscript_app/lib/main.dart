//Basic App Stuff
import 'dart:async';
import 'package:flutter/material.dart';

// Pages
import 'pages/home_page.dart';
import 'pages/camera_page.dart';
// import 'pages/files_page.dart';
import 'pages/code_page.dart';
// import 'pages/opencv_page.dart';
import 'pages/debug_page.dart';

//Camera Related
import 'package:get/get.dart';

// Import to include Cross-Page Updater
import '/utils/fingertip_overlay.dart';
import 'package:provider/provider.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => ImageProviderNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    //Uses GetX version of Material App for Camera
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "SkyScripting",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 182, 48, 162)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'SkyScript'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }
  
  final List<Widget> _widgetOptions = <Widget>[    
    const HomePage(),
    const CameraPage(),
    DebugPage(),
    CodePage(),
    // CameraOpenCVPage()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final iconSize = size.width * 0.05;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home, size: iconSize), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.camera, size: iconSize), label: 'Camera'),
          BottomNavigationBarItem(icon: Icon(Icons.file_open, size: iconSize), label: 'Files'),
          BottomNavigationBarItem(icon: Icon(Icons.code, size: iconSize), label: 'SkyScript'),
          // BottomNavigationBarItem(icon: Icon(Icons.double_arrow, size: iconSize), label: 'FrameTransfer'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        selectedFontSize: size.width * 0.03,
        unselectedFontSize: size.width * 0.025,
        showUnselectedLabels: true,
      ),
    );
  }
}
