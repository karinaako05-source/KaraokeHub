import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/song_item.dart';
import 'audio_engine_service.dart';

class VideokeFlowManager extends ChangeNotifier {
  static final VideokeFlowManager _instance = VideokeFlowManager._internal();
  factory VideokeFlowManager() => _instance;
  VideokeFlowManager._internal() {
    _audio.onSongEnded = _handleSongEnded;
  }

  final AudioEngineService _audio = AudioEngineService();

  SongItem? _currentSong;
  SongItem? get currentSong => _currentSong;

  final List<SongItem> _queue = [];
  List<SongItem> get queue => List.unmodifiable(_queue);

  final List<SongItem> _history = [];
  List<SongItem> get history => List.unmodifiable(_history);

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  int _pitch = 0; // -12 to +12 semitones
  int get pitch => _pitch;

  double _tempo = 1.0; // 0.5 to 1.5
  double get tempo => _tempo;

  int? _lastScore;
  int? get lastScore => _lastScore;

  bool _isScoring = false;
  bool get isScoring => _isScoring;

  Future<void> playSong(SongItem song, {bool fromQueue = false}) async {
    if (_currentSong != null && _currentSong!.code != song.code) {
      _history.add(_currentSong!);
    }
    if (fromQueue) {
      _queue.removeWhere((item) => item.code == song.code);
    }

    _currentSong = song;
    _pitch = 0;
    _tempo = 1.0;
    _isScoring = false;
    _lastScore = null;

    bool loaded = false;
    if (song.isBlob) {
      loaded = await _audio.loadBlobSong(
        offset: song.blobOffset!,
        length: song.blobLength!,
      );
    } else {
      loaded = await _audio.loadSong(song.filePath);
    }

    if (loaded) {
      await _audio.play();
      _isPlaying = true;
    } else {
      _isPlaying = false;
    }
    notifyListeners();
  }

  Future<void> reserve(SongItem song, {bool priority = false}) async {
    if (priority) {
      _queue.removeWhere((item) => item.code == song.code);
      _queue.insert(0, song);
    } else {
      if (!_queue.any((item) => item.code == song.code)) {
        _queue.add(song);
      }
    }

    // If machine is idle, automatically load and play first reserved song
    if (_currentSong == null || !_isPlaying) {
      await next();
    } else {
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_currentSong == null) {
      if (_queue.isNotEmpty) {
        await next();
      }
      return;
    }

    if (_isPlaying) {
      await _audio.pause();
      _isPlaying = false;
    } else {
      await _audio.play();
      _isPlaying = true;
    }
    notifyListeners();
  }

  Future<void> play() async {
    if (_currentSong != null) {
      await _audio.play();
      _isPlaying = true;
      notifyListeners();
    } else if (_queue.isNotEmpty) {
      await next();
    }
  }

  Future<void> pause() async {
    await _audio.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> stop() async {
    await _audio.stop();
    _isPlaying = false;
    _currentSong = null;
    notifyListeners();
  }

  Future<void> next() async {
    if (_queue.isEmpty) {
      await stop();
      return;
    }
    final nextSong = _queue.removeAt(0);
    await playSong(nextSong, fromQueue: true);
  }

  Future<void> previous() async {
    if (_history.isEmpty) return;
    final prevSong = _history.removeLast();
    await playSong(prevSong);
  }

  Future<void> replay() async {
    if (_currentSong == null) return;
    await _audio.seekTo(0);
    await _audio.play();
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> setPitch(int newPitch) async {
    _pitch = newPitch.clamp(-12, 12);
    await _audio.setPitch(_pitch);
    notifyListeners();
  }

  Future<void> setTempo(double newTempo) async {
    _tempo = (newTempo * 10).round() / 10;
    _tempo = _tempo.clamp(0.5, 1.5);
    await _audio.setTempo(_tempo);
    notifyListeners();
  }

  void removeFromQueue(String code) {
    _queue.removeWhere((item) => item.code == code);
    notifyListeners();
  }

  void clearQueue() {
    _queue.clear();
    notifyListeners();
  }

  void _handleSongEnded() async {
    // Generate authentic videoke score (85 - 100)
    final random = Random();
    final score = 85 + random.nextInt(16); // 85 to 100
    _lastScore = score;
    _isScoring = true;
    notifyListeners();

    // Play corresponding fanfare SFX
    String sfxName;
    if (score == 100) {
      sfxName = 'score_100';
    } else if (score >= 91) {
      sfxName = 'score_91_99';
    } else if (score >= 81) {
      sfxName = 'score_81_90';
    } else if (score >= 76) {
      sfxName = 'score_76_80';
    } else {
      sfxName = 'score_61_75';
    }
    await _audio.playSfx(sfxName);

    // Wait 4 seconds for score display then advance to next queued song
    Future.delayed(const Duration(seconds: 4), () {
      _isScoring = false;
      notifyListeners();
      next();
    });
  }
}
