import 'package:flutter/material.dart';
import 'pages/electric_page.dart';
import 'pages/weather_page.dart';

void main() {
    const mapTilerKey = String.fromEnvironment('MAPTILER_KEY');

    assert(
    mapTilerKey.isNotEmpty,
    'Thiếu MAPTILER_KEY. '
        'Hãy chạy bằng --dart-define=MAPTILER_KEY=...',
    );

    runApp(const MyApp());
  }


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentPage = 0;

  final List<Widget> pages = const [
      ElectricPage(),
      WeatherPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Chỗ xem lịch cúp điện'),
      //  centerTitle: true,
      // ),

      body: pages[currentPage],

      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.electrical_services),
              label: 'Điện'),
          NavigationDestination(
              icon: Icon(Icons.sunny),
              label: 'Thời tiết')
        ],
        selectedIndex: currentPage,
        onDestinationSelected: (int index) {
          setState(() {
            currentPage = index;
          });
        },
      ),
    );
  }
}