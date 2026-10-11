import 'dart:async';
import 'package:flutter/services.dart';

class AudioEngineService {
  static final AudioEngineService _instance = AudioEngineService._internal();
  factory AudioEngineService() => _instance;
  AudioEngineService._internal() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static const MethodChannel _channel = MethodChannel('com.karaokehub.next/audio_engine');

  VoidCallback? onSongEnded;

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onSongEnded') {
      onSongEnded?.call();
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
    String blobPath = '/sdcard/KaraokeHub/karaokehub-private-020/content/idx/shubblob',
    required int offset,
    required int length,
  }) async {
    try {
      final res = await _channel.invokeMethod<bool>('loadBlobSong', {
        'blobPath': blobPath,
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
