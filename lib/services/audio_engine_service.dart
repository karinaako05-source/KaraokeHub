import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AudioEngineService {
  static final AudioEngineService _instance = AudioEngineService._internal();
  factory AudioEngineService() => _instance;
  AudioEngineService._internal();

  final AudioPlayer _player = AudioPlayer();
  static const MethodChannel _nativeChannel = MethodChannel('com.karaokehub.next/audio_engine');

  Future<void> initEngine() async {
    try {
      await _nativeChannel.invokeMethod('initEngine');
    } catch (_) {}
  }

  Future<void> playSong(String? filePath) async {
    try {
      if (filePath != null && filePath.isNotEmpty) {
        await _player.stop();
        await _player.play(DeviceFileSource(filePath));
        return;
      }
    } catch (_) {}

    // Fallback: trigger native BASS stream
    try {
      await _nativeChannel.invokeMethod('play');
    } catch (_) {}
  }

  Future<void> play() async {
    try {
      await _player.resume();
    } catch (_) {}
    try {
      await _nativeChannel.invokeMethod('play');
    } catch (_) {}
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (_) {}
    try {
      await _nativeChannel.invokeMethod('pause');
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _nativeChannel.invokeMethod('stop');
    } catch (_) {}
  }

  Future<void> setPitch(int semitones) async {
    try {
      // Audio pitch adjustment
      final rate = 1.0 + (semitones * 0.05);
      await _player.setPlaybackRate(rate.clamp(0.5, 2.0));
      await _nativeChannel.invokeMethod('setPitch', {'semitones': semitones});
    } catch (_) {}
  }

  Future<void> setTempo(double rate) async {
    try {
      await _player.setPlaybackRate(rate.clamp(0.5, 2.0));
      await _nativeChannel.invokeMethod('setTempo', {'rate': rate});
    } catch (_) {}
  }
}
