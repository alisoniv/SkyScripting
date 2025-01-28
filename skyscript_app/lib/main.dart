//Basic App Stuff
import 'dart:async';
import 'package:flutter/material.dart';

// Pages
import 'pages/home_page.dart';
import 'pages/camera_page.dart';
import 'pages/files_page.dart';
import 'pages/code_page.dart';

//Camera Related
import 'package:get/get.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
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
      home: const MyHomePage(title: 'SkyScripting'),
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
    const FilesPage(),
    CodePage()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
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
          BottomNavigationBarItem(icon: Icon(Icons.code), label: 'Python')
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.purple,
        onTap: _onItemTapped,
      ),
    );
  }
}
