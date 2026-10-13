import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

enum ChannelMode { stereo, left, right, mixed }

enum BackgroundMode { video, slideshow, camera, none }

enum LyricAlignment { center, split, closeSplit }

class AppSettings extends ChangeNotifier {
  static final AppSettings _instance = AppSettings._internal();
  factory AppSettings() => _instance;
  AppSettings._internal() {
    loadSettings();
  }

  static const String _settingsFilePath =
      '/sdcard/Download/KaraokeHub/karaokehub_settings.json';

  // --- 1. SoundFonts & Content ---
  String? selectedSf2Path =
      '/sdcard/Download/KaraokeHub/content/sound/soundfont.sf2';
  String? selectedSf2Name = 'soundfont.sf2';

  // --- 2. BGV (Background Visual) ---
  BackgroundMode bgvMode = BackgroundMode.video;
  bool bgvContinuousVideo = false;
  String? bgvCustomPath = '/sdcard/Download/KaraokeHub/content/bgv';
  int bgvPhotoIntervalSeconds = 5;
  int bgvPhotoAnimation = 1; // 0: None, 1: Fade, 2: Slide, 3: Zoom
  int bgvCameraLens = 0; // 0: Back, 1: Front, 2: External

  // --- 3. Audio & MIDI Engine ---
  int midiMasterVolume = 100; // 0-200%
  int mp3MasterVolume = 100; // 0-200%
  bool vocalChorusMode = true; // true: Chorus (MIDI+MP3), false: Multiplex
  int midiReverb = 4; // 0: Off, 1: Low, 2: Med, 3: High, 4: Default
  int midiChorus = 4; // 0: Off, 1: Low, 2: Med, 3: High, 4: Default
  int midiPolyphony = 512; // 64, 128, 192, 256, 512
  int melodyChannel = 1; // 1-16
  int midiSampleRate = 44100; // 22050, 44100, 48000, 96000
  ChannelMode channelMode = ChannelMode.stereo;
  int typingSoundVolume = 2; // 0: Off, 1: Low, 2: Mid, 3: High

  // --- 4. Lyrics ---
  LyricAlignment lyricAlignment = LyricAlignment.center;
  int lyricAnimation =
      0; // 0: None, 1: Fade, 2: Wipe, 3: Crossfade, 4: Flip, 5: Bounce
  int countdownStyle =
      0; // 0: Text Animated, 1: Text Static, 2: Star, 3: Stacked Img, etc.
  double outlineThickness = 6.0; // 2, 4, 6, 8, 10, 12
  double fontSizePortrait = 42.0; // 20-120
  double fontSizeLandscape = 63.0; // 20-150
  bool lyricShowShadow = true;
  bool fourLinesPortrait = false;
  bool useRandomLyricColor = false;
  int lyricHighlightColor = 0xFF00F2FE;
  bool randomizeIntroStyle = false;
  int lyricFontType = 0; // 0: Default, 1: Roboto, 2: Serif, etc.

  // --- 5. Scoring ---
  bool scoreEnabled = true;
  int scoreMode = 1; // 0: Off, 1: Random, 2: Microphone
  int scoreDifficulty = 1; // 0: Low, 1: Mid, 2: High
  int fanfareLevel = 2; // 0: Off, 1: Low, 2: Mid, 3: High

  // --- 6. Remote Broadcasting ---
  bool remoteEnabled = false;
  int remotePort = 48080;

  // --- 7. Behavior ---
  bool showDialogLandscape = true;
  bool hideControlsLandscape = false;

  Map<String, dynamic> get audioSettings => {
        'midiVolume': midiMasterVolume / 100,
        'mediaVolume': mp3MasterVolume / 100,
        'polyphony': midiPolyphony,
        'reverb': midiReverb,
        'chorus': midiChorus,
      };

  void loadSettings({String path = _settingsFilePath}) {
    try {
      final f = File(path);
      if (f.existsSync()) {
        final data = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        if (data.containsKey('selectedSf2Path')) {
          selectedSf2Path = data['selectedSf2Path'] as String?;
        }
        selectedSf2Name = data['selectedSf2Name'] as String? ?? selectedSf2Name;

        bgvMode = BackgroundMode.values[data['bgvMode'] as int? ?? 0];
        bgvContinuousVideo = data['bgvContinuousVideo'] as bool? ?? false;
        bgvCustomPath = data['bgvCustomPath'] as String? ?? bgvCustomPath;
        bgvPhotoIntervalSeconds = data['bgvPhotoIntervalSeconds'] as int? ?? 5;
        bgvPhotoAnimation = data['bgvPhotoAnimation'] as int? ?? 1;

        midiMasterVolume = data['midiMasterVolume'] as int? ?? 100;
        mp3MasterVolume = data['mp3MasterVolume'] as int? ?? 100;
        vocalChorusMode = data['vocalChorusMode'] as bool? ?? true;
        midiReverb = data['midiReverb'] as int? ?? 4;
        midiChorus = data['midiChorus'] as int? ?? 4;
        midiPolyphony = data['midiPolyphony'] as int? ?? 512;
        melodyChannel = data['melodyChannel'] as int? ?? 1;
        midiSampleRate = data['midiSampleRate'] as int? ?? 44100;
        channelMode = ChannelMode.values[data['channelMode'] as int? ?? 0];
        typingSoundVolume = data['typingSoundVolume'] as int? ?? 2;

        lyricAlignment =
            LyricAlignment.values[data['lyricAlignment'] as int? ?? 0];
        lyricAnimation = data['lyricAnimation'] as int? ?? 0;
        countdownStyle = data['countdownStyle'] as int? ?? 0;
        outlineThickness =
            (data['outlineThickness'] as num?)?.toDouble() ?? 6.0;
        fontSizePortrait =
            (data['fontSizePortrait'] as num?)?.toDouble() ?? 42.0;
        fontSizeLandscape =
            (data['fontSizeLandscape'] as num?)?.toDouble() ?? 63.0;
        lyricShowShadow = data['lyricShowShadow'] as bool? ?? true;
        fourLinesPortrait = data['fourLinesPortrait'] as bool? ?? false;
        useRandomLyricColor = data['useRandomLyricColor'] as bool? ?? false;
        lyricHighlightColor = data['lyricHighlightColor'] as int? ?? 0xFF00F2FE;
        randomizeIntroStyle = data['randomizeIntroStyle'] as bool? ?? false;
        lyricFontType = data['lyricFontType'] as int? ?? 0;

        scoreEnabled = data['scoreEnabled'] as bool? ?? true;
        scoreMode = data['scoreMode'] as int? ?? 1;
        scoreDifficulty = data['scoreDifficulty'] as int? ?? 1;
        fanfareLevel = data['fanfareLevel'] as int? ?? 2;

        remoteEnabled = data['remoteEnabled'] as bool? ?? false;
        remotePort = data['remotePort'] as int? ?? 48080;

        showDialogLandscape = data['showDialogLandscape'] as bool? ?? true;
        hideControlsLandscape = data['hideControlsLandscape'] as bool? ?? false;
      }
    } catch (_) {}
    notifyListeners();
  }

  void saveSettings({String path = _settingsFilePath}) {
    try {
      final f = File(path);
      f.parent.createSync(recursive: true);
      final map = {
        'selectedSf2Path': selectedSf2Path,
        'selectedSf2Name': selectedSf2Name,
        'bgvMode': bgvMode.index,
        'bgvContinuousVideo': bgvContinuousVideo,
        'bgvCustomPath': bgvCustomPath,
        'bgvPhotoIntervalSeconds': bgvPhotoIntervalSeconds,
        'bgvPhotoAnimation': bgvPhotoAnimation,
        'midiMasterVolume': midiMasterVolume,
        'mp3MasterVolume': mp3MasterVolume,
        'vocalChorusMode': vocalChorusMode,
        'midiReverb': midiReverb,
        'midiChorus': midiChorus,
        'midiPolyphony': midiPolyphony,
        'melodyChannel': melodyChannel,
        'midiSampleRate': midiSampleRate,
        'channelMode': channelMode.index,
        'typingSoundVolume': typingSoundVolume,
        'lyricAlignment': lyricAlignment.index,
        'lyricAnimation': lyricAnimation,
        'countdownStyle': countdownStyle,
        'outlineThickness': outlineThickness,
        'fontSizePortrait': fontSizePortrait,
        'fontSizeLandscape': fontSizeLandscape,
        'lyricShowShadow': lyricShowShadow,
        'fourLinesPortrait': fourLinesPortrait,
        'useRandomLyricColor': useRandomLyricColor,
        'lyricHighlightColor': lyricHighlightColor,
        'randomizeIntroStyle': randomizeIntroStyle,
        'lyricFontType': lyricFontType,
        'scoreEnabled': scoreEnabled,
        'scoreMode': scoreMode,
        'scoreDifficulty': scoreDifficulty,
        'fanfareLevel': fanfareLevel,
        'remoteEnabled': remoteEnabled,
        'remotePort': remotePort,
        'showDialogLandscape': showDialogLandscape,
        'hideControlsLandscape': hideControlsLandscape,
      };
      f.writeAsStringSync(jsonEncode(map));
    } catch (_) {}
    notifyListeners();
  }

  void resetToDefaults() {
    selectedSf2Path = '/sdcard/Download/KaraokeHub/content/sound/soundfont.sf2';
    selectedSf2Name = 'soundfont.sf2';
    bgvMode = BackgroundMode.video;
    bgvContinuousVideo = false;
    bgvCustomPath = '/sdcard/Download/KaraokeHub/content/bgv';
    bgvPhotoIntervalSeconds = 5;
    bgvPhotoAnimation = 1;
    midiMasterVolume = 100;
    mp3MasterVolume = 100;
    vocalChorusMode = true;
    midiReverb = 4;
    midiChorus = 4;
    midiPolyphony = 512;
    melodyChannel = 1;
    midiSampleRate = 44100;
    channelMode = ChannelMode.stereo;
    typingSoundVolume = 2;
    lyricAlignment = LyricAlignment.center;
    lyricAnimation = 0;
    countdownStyle = 0;
    outlineThickness = 6.0;
    fontSizePortrait = 42.0;
    fontSizeLandscape = 63.0;
    lyricShowShadow = true;
    fourLinesPortrait = false;
    useRandomLyricColor = false;
    lyricHighlightColor = 0xFF00F2FE;
    randomizeIntroStyle = false;
    lyricFontType = 0;
    scoreEnabled = true;
    scoreMode = 1;
    scoreDifficulty = 1;
    fanfareLevel = 2;
    remoteEnabled = false;
    remotePort = 48080;
    showDialogLandscape = true;
    hideControlsLandscape = false;
    saveSettings();
  }
}
