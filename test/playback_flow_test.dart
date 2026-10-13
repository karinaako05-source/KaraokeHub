import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karaokehub_next/models/app_settings.dart';
import 'package:karaokehub_next/models/song_item.dart';
import 'package:karaokehub_next/screens/karaoke_player_screen.dart';
import 'package:karaokehub_next/services/audio_engine_service.dart';
import 'package:karaokehub_next/services/song_catalog_service.dart';
import 'package:karaokehub_next/services/videoke_flow_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.karaokehub.next/audio_engine');
  const first = SongItem(
      code: '101',
      title: 'First',
      artist: 'Artist',
      genre: 'MP3',
      filePath: '/first.mp3');
  const second = SongItem(
      code: '102',
      title: 'Second',
      artist: 'Artist',
      genre: 'MP3',
      filePath: '/second.mp3');
  final calls = <MethodCall>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late VideokeFlowManager flow;
  bool playSucceeds = true;
  bool loadSucceeds = true;
  Future<Object?> Function(MethodCall)? intercept;

  Future<void> event(String method, Object args) async {
    final done = Completer<void>();
    messenger.handlePlatformMessage(
        channel.name,
        const StandardMethodCodec().encodeMethodCall(MethodCall(method, args)),
        (_) => done.complete());
    await done.future;
  }

  setUp(() async {
    calls.clear();
    playSucceeds = true;
    loadSucceeds = true;
    intercept = null;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (intercept != null) return intercept!(call);
      switch (call.method) {
        case 'play':
          return playSucceeds;
        case 'loadSong':
        case 'loadBlobSong':
          return loadSucceeds;
        case 'getLyrics':
          return [];
        case 'getPosition':
          return 500;
        case 'getDuration':
          return 10000;
        case 'getSoundFonts':
          return [];
        default:
          return true;
      }
    });
    flow = VideokeFlowManager();
    await flow.stop();
    flow.clearQueue();
    final settings = AppSettings();
    settings.scoreEnabled = true;
    settings.scoreMode = 1;
    settings.scoreDifficulty = 0;
    settings.fanfareLevel = 2;
    settings.bgvMode = BackgroundMode.none;
    calls.clear();
  });

  tearDown(() async {
    await flow.stop();
    AudioEngineService().onLyricsLoaded = null;
    intercept = null;
  });

  test('tempo controls decrease and increase in five percentage points',
      () async {
    await flow.setTempo(1.0);
    await flow.setTempo(flow.tempo - 0.05);
    expect(flow.tempo, 0.95);
    await flow.setTempo(flow.tempo + 0.05);
    expect(flow.tempo, 1.0);
  });

  test('a failed native start does not report playing', () async {
    playSucceeds = false;
    await flow.playSong(first);
    expect(flow.isPlaying, isFalse);
    expect(flow.playbackError, isNotNull);
  });

  test('a failed load never starts playback', () async {
    loadSucceeds = false;
    await flow.playSong(first);
    expect(calls.where((call) => call.method == 'play'), isEmpty);
    expect(flow.isPlaying, isFalse);
  });

  test('the next song resets native tuning before play', () async {
    await flow.playSong(first);
    await flow.setPitch(3);
    await flow.setTempo(1.2);
    calls.clear();
    await flow.playSong(second);
    final methods = calls.map((call) => call.method).toList();
    expect(methods.indexOf('stop'), lessThan(methods.indexOf('loadSong')));
    expect(methods.indexOf('setPitch'), lessThan(methods.indexOf('play')));
    expect(
        calls
            .firstWhere((call) => call.method == 'setPitch')
            .arguments['semitones'],
        0);
    expect(
        calls.firstWhere((call) => call.method == 'setTempo').arguments['rate'],
        1.0);
  });

  test('old scoring timer cannot stop a replacement song', () async {
    await flow.playSong(first);
    flow.showScore();
    await Future<void>.delayed(Duration.zero);
    expect(flow.isScoring, isTrue);
    await flow.playSong(second);
    await Future<void>.delayed(const Duration(milliseconds: 4200));
    expect(flow.currentSong?.code, second.code);
    expect(flow.isPlaying, isTrue);
  });

  test('disabled scoring advances the queue without fanfare', () async {
    AppSettings().scoreEnabled = false;
    await flow.playSong(first);
    await flow.reserve(second);
    calls.clear();
    await event('onSongEnded', {'sessionId': flow.sessionId});
    await Future<void>.delayed(Duration.zero);
    expect(flow.currentSong?.code, second.code);
    expect(flow.isScoring, isFalse);
    expect(calls.where((call) => call.method == 'playSfx'), isEmpty);
  });

  test('silent fanfare still displays a score and advances', () async {
    AppSettings().fanfareLevel = 0;
    await flow.playSong(first);
    await flow.reserve(second);
    calls.clear();
    await event('onSongEnded', {'sessionId': flow.sessionId});
    await Future<void>.delayed(Duration.zero);
    expect(flow.lastScore, isNotNull);
    expect(calls.where((call) => call.method == 'playSfx'), isEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 4200));
    expect(flow.currentSong?.code, second.code);
  });

  test('stale completion and lyrics cannot update the new song', () async {
    await flow.playSong(first);
    final oldSession = flow.sessionId;
    await flow.playSong(second);
    await event('onSongEnded', {'sessionId': oldSession});
    await event('onLyricsLoaded', {
      'sessionId': oldSession,
      'lyrics': [
        {'text': 'Old', 'timeMs': 0}
      ]
    });
    await Future<void>.delayed(Duration.zero);
    expect(flow.isScoring, isFalse);
    expect(AudioEngineService().currentLyrics, isEmpty);
    expect(flow.currentSong?.code, second.code);
  });

  test('catalog contains no bundled sample songs and coalesces reloads',
      () async {
    final catalog = SongCatalogService();
    await catalog.reloadCatalog();
    final firstLoad = catalog.reloadCatalog();
    final secondLoad = catalog.reloadCatalog();
    expect(identical(firstLoad, secondLoad), isTrue);
    await firstLoad;
    expect(
        catalog.songs
            .where((song) => song.filePath?.startsWith('assets/') == true),
        isEmpty);
    expect(File('assets/audio/test.mp3').existsSync(), isFalse);
    expect(File('assets/audio/sample.mid').existsSync(), isFalse);
    expect(File('assets/audio/test.mid').existsSync(), isFalse);
  });

  test('automatic SoundFont selection survives a disk round trip', () async {
    final directory =
        await Directory.systemTemp.createTemp('karaokehub-settings-');
    try {
      final path = '${directory.path}/settings.json';
      final settings = AppSettings();
      settings.selectedSf2Path = null;
      settings.selectedSf2Name = 'Automatic (Best Available)';
      settings.saveSettings(path: path);
      settings.selectedSf2Path = '/previous.sf2';
      settings.loadSettings(path: path);
      expect(settings.selectedSf2Path, isNull);
      expect(settings.selectedSf2Name, 'Automatic (Best Available)');
      await flow.pause();
    } finally {
      await directory.delete(recursive: true);
    }
  });
  testWidgets(
      'leaving the player during polling does not setState after dispose',
      (tester) async {
    await tester.runAsync(() => flow.playSong(first));
    final position = Completer<int>();
    intercept = (call) async {
      if (call.method == 'getPosition') return position.future;
      if (call.method == 'getDuration') return 10000;
      if (call.method == 'getLyrics') return [];
      return true;
    };
    await tester.pumpWidget(const MaterialApp(home: KaraokePlayerScreen()));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpWidget(const SizedBox.shrink());
    position.complete(500);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
