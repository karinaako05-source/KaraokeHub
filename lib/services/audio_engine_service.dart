import 'package:flutter/services.dart';

class AudioEngineService {
  static final AudioEngineService _instance = AudioEngineService._internal();
  factory AudioEngineService() => _instance;
  AudioEngineService._internal();

  static const MethodChannel _channel = MethodChannel('com.karaokehub.next/audio_engine');

  Future<bool> initEngine() async {
    try {
      final res = await _channel.invokeMethod<bool>('initEngine');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> loadSong(String path) async {
    try {
      final res = await _channel.invokeMethod<bool>('loadSong', {'path': path});
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

  Future<bool> setPitch(int semitones) async {
    try {
      final res = await _channel.invokeMethod<bool>('setPitch', {'semitones': semitones});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setTempo(double rate) async {
    try {
      final res = await _channel.invokeMethod<bool>('setTempo', {'rate': rate});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
