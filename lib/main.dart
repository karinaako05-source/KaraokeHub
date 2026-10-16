import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void _logCrash(String type, Object error, StackTrace? stack) {
  final now = DateTime.now().toIso8601String();
  final message =
      '[$now] [$type]\n$error\n${stack ?? ""}\n----------------------------------------\n';
  final candidates = [
    '/sdcard/Android/data/com.karaokehub.next/files/karaoke_crash.log',
    '/storage/emulated/0/Android/data/com.karaokehub.next/files/karaoke_crash.log',
    '/sdcard/Download/karaoke_crash.log',
    '/storage/emulated/0/Download/karaoke_crash.log',
  ];
  for (final path in candidates) {
    try {
      final file = File(path);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(
        message,
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {}
  }
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
