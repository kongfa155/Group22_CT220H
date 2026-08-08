import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'pages/electric_page.dart';
import 'pages/weather_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const mapTilerKey = "b2Qcb2a8OPn4k4DuPp3Y";
  // String.fromEnvironment('MAPTILER_KEY');

  assert(
    mapTilerKey.isNotEmpty,
    'Thiếu MAPTILER_KEY. '
    'Hãy chạy bằng --dart-define=MAPTILER_KEY=...',
  );

  await initializeDateFormatting('vi');

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

  final List<Widget> pages = const [ElectricPage(), WeatherPage()];

  void _showAboutUs() {
    showAboutDialog(
      context: context,
      applicationName: 'Electric and Weather',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.electric_bolt,
        size: 48,
        color: Colors.amber,
      ),
      children: const [
        SizedBox(height: 8),
        Text(
          'Ứng dụng xem lịch cúp điện và dự báo thời tiết tích hợp bản đồ trực tuyến.',
        ),
        SizedBox(height: 8),
        Text('Phát triển bởi Nhóm 22 - CT220H.'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Tiêu đề chung cho cả bên điện và thời tiết (Tui xóa cái tiêu đề thời tiết cũ của ông r nha TDuy,đem nó ra đây)
      appBar: AppBar(
        title: Text(currentPage == 0 ? 'Lịch cúp điện' : 'Dự báo thời tiết'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'About Us',
            onPressed: _showAboutUs,
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: pages[currentPage],

      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.electrical_services),
            label: 'Điện',
          ),
          NavigationDestination(icon: Icon(Icons.sunny), label: 'Thời tiết'),
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
