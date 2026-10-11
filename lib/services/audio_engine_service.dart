import 'package:flutter/services.dart';

class AudioEngineService {
  static final AudioEngineService _instance = AudioEngineService._internal();
  factory AudioEngineService() => _instance;
  AudioEngineService._internal();

  static const MethodChannel _channel = MethodChannel('com.karaokehub.next/audio_engine');

  Future<void> initEngine() async {
    try {
      await _channel.invokeMethod('initEngine');
    } catch (_) {}
  }

  Future<void> playSong(String? path) async {
    try {
      await _channel.invokeMethod('loadSong', {'path': path});
      await _channel.invokeMethod('play');
    } catch (_) {}
  }

  Future<void> play() async {
    try {
      await _channel.invokeMethod('play');
    } catch (_) {}
  }

  Future<void> pause() async {
    try {
      await _channel.invokeMethod('pause');
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
    } catch (_) {}
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
}
