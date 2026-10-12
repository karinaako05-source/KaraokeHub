import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

class AudioEngineService {
  static final AudioEngineService _instance = AudioEngineService._internal();
  factory AudioEngineService() => _instance;
  AudioEngineService._internal() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static const MethodChannel _channel = MethodChannel('com.karaokehub.next/audio_engine');

  VoidCallback? onSongEnded;
  void Function(List<Map<String, dynamic>>)? onLyricsLoaded;

  List<Map<String, dynamic>> _currentLyrics = [];
  List<Map<String, dynamic>> get currentLyrics => List.unmodifiable(_currentLyrics);

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onSongEnded') {
      onSongEnded?.call();
    } else if (call.method == 'onLyricsLoaded') {
      final raw = call.arguments;
      if (raw is List) {
        _currentLyrics = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        onLyricsLoaded?.call(_currentLyrics);
      }
    }
  }

  Future<List<Map<String, dynamic>>> getLyrics() async {
    try {
      final res = await _channel.invokeMethod<List>('getLyrics');
      if (res != null) {
        _currentLyrics = res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        return _currentLyrics;
      }
    } catch (_) {}
    return _currentLyrics;
  }

  Future<bool> checkStoragePermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('checkStoragePermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestStoragePermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('requestStoragePermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> initEngine() async {
    try {
      final res = await _channel.invokeMethod<bool>('initEngine');
      return res ?? true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getSynthStatus() async {
    try {
      final res = await _channel.invokeMethod<Map>('getSynthStatus');
      if (res != null) {
        return Map<String, dynamic>.from(res);
      }
    } catch (_) {}
    return {'soundfontActive': false, 'soundfontPath': 'Standard Synth'};
  }

  Future<bool> setSoundFont(String? path) async {
    try {
      final res = await _channel.invokeMethod<bool>('setSoundFont', {'path': path});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getSoundFonts() async {
    try {
      final res = await _channel.invokeMethod<List>('getSoundFonts');
      if (res != null) {
        return res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> loadSong(String? path) async {
    if (path == null || path.isEmpty) return false;
    try {
      final res = await _channel.invokeMethod<bool>('loadSong', {'path': path});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> loadBlobSong({
    String? blobPath,
    required int offset,
    required int length,
  }) async {
    String resolvedPath = blobPath ?? '';
    if (resolvedPath.isEmpty) {
      final candidates = [
        '/sdcard/Download/KaraokeHub/content/idx/shubblob',
        '/sdcard/Download/karaokehub/content/idx/shubblob',
        '/storage/emulated/0/Download/KaraokeHub/content/idx/shubblob',
        '/storage/emulated/0/Download/karaokehub/content/idx/shubblob',
        '/sdcard/Download/idx/shubblob',
        '/sdcard/Download/shubblob',
        '/storage/emulated/0/Download/idx/shubblob',
        '/storage/emulated/0/Download/shubblob',
        '/sdcard/KaraokeHub/karaokehub-private-020/content/idx/shubblob',
        '/sdcard/KaraokeHub/idx/shubblob',
        '/storage/emulated/0/KaraokeHub/karaokehub-private-020/content/idx/shubblob',
      ];
      for (final p in candidates) {
        try {
          if (File(p).existsSync()) {
            resolvedPath = p;
            break;
          }
        } catch (_) {}
      }
      if (resolvedPath.isEmpty) {
        resolvedPath = '/sdcard/Download/idx/shubblob';
      }
    }

    try {
      final res = await _channel.invokeMethod<bool>('loadBlobSong', {
        'blobPath': resolvedPath,
        'offset': offset,
        'length': length,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> play() async {
    try {
      final res = await _channel.invokeMethod<bool>('play');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> pause() async {
    try {
      final res = await _channel.invokeMethod<bool>('pause');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> stop() async {
    try {
      final res = await _channel.invokeMethod<bool>('stop');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> seekTo(int positionMs) async {
    try {
      final res = await _channel.invokeMethod<bool>('seekTo', {'positionMs': positionMs});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<int> getPosition() async {
    try {
      final res = await _channel.invokeMethod<int>('getPosition');
      return res ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getDuration() async {
    try {
      final res = await _channel.invokeMethod<int>('getDuration');
      return res ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> setPitch(int semitones) async {
    try {
      await _channel.invokeMethod('setPitch', {'semitones': semitones});
    } catch (_) {}
  }

  Future<void> setTempo(double rate) async {
    try {
      await _channel.invokeMethod('setTempo', {'rate': rate});
    } catch (_) {}
  }

  Future<void> playSfx(String name) async {
    try {
      await _channel.invokeMethod('playSfx', {'name': name});
    } catch (_) {}
  }
}
