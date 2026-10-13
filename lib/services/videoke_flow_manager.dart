import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/song_item.dart';
import '../models/app_settings.dart';
import 'audio_engine_service.dart';

class VideokeFlowManager extends ChangeNotifier {
  static final VideokeFlowManager _instance = VideokeFlowManager._internal();
  factory VideokeFlowManager() => _instance;
  VideokeFlowManager._internal() {
    _audio.onSongEnded = (session) => _handleSongEnded(session);
    _settings.addListener(_applySettings);
    _applySettings();
  }

  final AudioEngineService _audio = AudioEngineService();
  final AppSettings _settings = AppSettings();
  final List<SongItem> _queue = [];
  final List<SongItem> _history = [];
  Future<void> _operations = Future.value();
  Timer? _scoreTimer;
  int _sessionId = 0;
  SongItem? _currentSong;
  bool _isPlaying = false;
  bool _isScoring = false;
  int _pitch = 0;
  double _tempo = 1.0;
  int? _lastScore;
  String? _playbackError;

  SongItem? get currentSong => _currentSong;
  List<SongItem> get queue => List.unmodifiable(_queue);
  List<SongItem> get history => List.unmodifiable(_history);
  bool get isPlaying => _isPlaying;
  bool get isScoring => _isScoring;
  int get pitch => _pitch;
  double get tempo => _tempo;
  int? get lastScore => _lastScore;
  String? get playbackError => _playbackError;
  int get sessionId => _sessionId;

  Future<void> _serialize(Future<void> Function() operation) {
    final result = _operations.then((_) => operation());
    _operations = result.catchError((Object error, StackTrace stack) {
      _playbackError = 'Audio operation failed: $error';
      debugPrint('Audio operation failed: $error');
      notifyListeners();
    });
    return _operations;
  }

  void _applySettings() {
    unawaited(
      _serialize(() async {
        await _audio.applySettings(_settings.audioSettings);
      }),
    );
  }

  int _beginSession() {
    _scoreTimer?.cancel();
    _scoreTimer = null;
    _isScoring = false;
    _lastScore = null;
    _isPlaying = false;
    _playbackError = null;
    ++_sessionId;
    _audio.beginSession(_sessionId);
    return _sessionId;
  }

  Future<void> playSong(SongItem song, {bool fromQueue = false}) {
    if (_currentSong != null && _currentSong!.code != song.code) {
      _history.add(_currentSong!);
    }
    if (fromQueue) _queue.removeWhere((item) => item.code == song.code);
    final session = _beginSession();
    _currentSong = song;
    _pitch = 0;
    _tempo = 1.0;
    notifyListeners();
    return _serialize(() async {
      if (session != _sessionId) return;
      await _audio.stop();
      if (session != _sessionId) return;
      await _audio.setSoundFont(_settings.selectedSf2Path);
      if (session != _sessionId) return;
      await _audio.applySettings(_settings.audioSettings);
      if (session != _sessionId) return;
      final loaded = song.isBlob
          ? await _audio.loadBlobSong(
              blobPath: song.blobPath,
              offset: song.blobOffset!,
              length: song.blobLength!,
              sessionId: session,
            )
          : await _audio.loadSong(song.filePath, sessionId: session);
      if (session != _sessionId) return;
      if (loaded) {
        await _audio.setPitch(0);
        await _audio.setTempo(1.0);
        if (session != _sessionId) return;
        final played = await _audio.play();
        if (session != _sessionId) return;
        _isPlaying = played;
      }
      if (!_isPlaying)
        _playbackError = 'Unable to play [${song.code}] ${song.title}';
      notifyListeners();
    });
  }

  Future<void> reserve(SongItem song, {bool priority = false}) async {
    if (priority) {
      _queue.removeWhere((item) => item.code == song.code);
      _queue.insert(0, song);
    } else if (!_queue.any((item) => item.code == song.code)) {
      _queue.add(song);
    }
    if (_currentSong == null && !_isScoring) {
      await next();
    } else {
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() => _isPlaying ? pause() : play();

  Future<void> play() async {
    if (_currentSong == null) {
      if (_queue.isNotEmpty) await next();
      return;
    }
    final session = _sessionId;
    await _serialize(() async {
      if (session != _sessionId || _isScoring) return;
      final played = await _audio.play();
      if (session != _sessionId) return;
      _isPlaying = played;
      _playbackError = played ? null : 'Unable to resume playback';
      notifyListeners();
    });
  }

  Future<void> pause() {
    final session = _sessionId;
    return _serialize(() async {
      if (session != _sessionId) return;
      final paused = await _audio.pause();
      if (session != _sessionId) return;
      if (paused) _isPlaying = false;
      notifyListeners();
    });
  }

  Future<void> stop() {
    final session = _beginSession();
    _currentSong = null;
    notifyListeners();
    return _serialize(() async {
      if (session == _sessionId) await _audio.stop();
    });
  }

  Future<void> next() {
    if (_queue.isEmpty) return stop();
    return playSong(_queue.first, fromQueue: true);
  }

  Future<void> previous() async {
    if (_history.isEmpty) return;
    final previous = _history.removeLast();
    await playSong(previous);
  }

  Future<void> replay() {
    final song = _currentSong;
    return song == null ? Future.value() : playSong(song);
  }

  Future<void> setPitch(int newPitch) {
    _pitch = newPitch.clamp(-12, 12);
    final pitch = _pitch;
    final session = _sessionId;
    notifyListeners();
    return _serialize(() async {
      if (session == _sessionId) await _audio.setPitch(pitch);
    });
  }

  Future<void> setTempo(double newTempo) {
    _tempo = ((newTempo * 20).round() / 20).clamp(0.5, 1.5);
    final tempo = _tempo;
    final session = _sessionId;
    notifyListeners();
    return _serialize(() async {
      if (session == _sessionId) await _audio.setTempo(tempo);
    });
  }

  void removeFromQueue(String code) {
    _queue.removeWhere((item) => item.code == code);
    notifyListeners();
  }

  void clearQueue() {
    _queue.clear();
    notifyListeners();
  }

  Future<bool> switchSoundFont(String? path) async {
    var ok = false;
    await _serialize(() async {
      ok = await _audio.setSoundFont(path);
    });
    if (ok) {
      _settings.selectedSf2Path = path;
      _settings.selectedSf2Name =
          path?.split('/').last ?? 'Automatic (Best Available)';
      _settings.saveSettings();
    }
    return ok;
  }

  void showScore() => _handleSongEnded(_sessionId, force: true);

  Future<void> _handleSongEnded(int session, {bool force = false}) async {
    if (session != _sessionId || _isScoring || _currentSong == null) return;
    _isScoring = true;
    _isPlaying = false;
    if (force) {
      await _serialize(() async {
        if (session == _sessionId) await _audio.pause();
      });
      if (session != _sessionId) return;
    }
    if (!_settings.scoreEnabled || _settings.scoreMode == 0) {
      await next();
      return;
    }
    final minimum = [85, 70, 61][_settings.scoreDifficulty.clamp(0, 2)];
    final score = minimum + Random().nextInt(101 - minimum);
    _lastScore = score;
    notifyListeners();
    if (_settings.fanfareLevel > 0) {
      final sound = score == 100
          ? 'score_100'
          : score >= 91
              ? 'score_91_99'
              : score >= 81
                  ? 'score_81_90'
                  : score >= 76
                      ? 'score_76_80'
                      : 'score_61_75';
      await _audio.playSfx(sound, volume: _settings.fanfareLevel / 3);
      if (session != _sessionId) return;
    }
    _scoreTimer = Timer(const Duration(seconds: 4), () {
      if (session != _sessionId || !_isScoring) return;
      unawaited(next());
    });
  }
}
