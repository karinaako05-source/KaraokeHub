import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void _logCrash(String type, Object error, StackTrace? stack) {
  try {
    final file = File('/sdcard/Download/karaoke_crash.log');
    final now = DateTime.now().toIso8601String();
    file.writeAsStringSync(
      '[$now] [$type]\n$error\n${stack ?? ""}\n----------------------------------------\n',
      mode: FileMode.append,
      flush: true,
    );
  } catch (_) {}
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    _logCrash('FLUTTER_ERROR', details.exception, details.stack);
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    _logCrash('ASYNC_ERROR', error, stack);
    return true;
  };

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
