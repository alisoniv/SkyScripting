//Basic App Stuff
import 'dart:async';
import 'package:flutter/material.dart';

// Pages
import 'pages/home_page.dart';
import 'pages/camera_page.dart';
import 'pages/files_page.dart';
import 'pages/drawing_page.dart';

//Camera Related
import 'package:skyscriptingapp/camera/scan_controller.dart';
// import 'package:get/instance_manager.dart';
import 'package:get/get.dart';
import 'package:skyscriptingapp/camera/camera_screen.dart';




Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

//Refactored from global_bindings.dart
class GlobalBindings extends Bindings{
  @override
  void dependencies() {
    Get.lazyPut<ScanController>(() => ScanController());
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    //Uses GetX version of Material App for Camera
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      // home: const CameraScreen(),
      home: const MyHomePage(title: 'SkyScripting'),
      title: "SkyScripting",
      initialBinding: GlobalBindings(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 182, 48, 162)),
        useMaterial3: true,
      )
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
  // late CameraController controller; //not supposed to be late, but temp fix

  @override
  void initState() {
    super.initState();
  }
  
  final List<Widget> _widgetOptions = <Widget>[    
    HomePage(),
    CameraScreen(),
    FilesPage(),
    DrawingPage()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // print("Selected index: $_selectedIndex");
    });
  }

  @override
  Widget build(BuildContext context) {

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
        items: const<BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.camera), label: 'Camera'),
          BottomNavigationBarItem(icon: Icon(Icons.file_open), label: 'Files'),
          BottomNavigationBarItem(icon: Icon(Icons.draw_outlined), label: 'Drawing')
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.purple,
        onTap: _onItemTapped,
      ),
    );
  }
}
