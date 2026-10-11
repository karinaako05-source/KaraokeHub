import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KaraokeHubNextApp());
}

class KaraokeHubNextApp extends StatelessWidget {
  const KaraokeHubNextApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KaraokeHub Next',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF06080E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F2FE),
          secondary: Color(0xFF9B51E0),
          surface: Color(0xFF101624),
        ),
        fontFamily: 'sans-serif',
      ),
      home: const DashboardScreen(),
    );
  }
}
