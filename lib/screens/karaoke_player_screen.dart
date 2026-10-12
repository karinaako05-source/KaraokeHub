import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/song_item.dart';
import '../services/audio_engine_service.dart';
import '../services/song_catalog_service.dart';
import '../services/videoke_flow_manager.dart';
import '../widgets/videoke_lyric_widget.dart';
import '../widgets/videoke_countdown_widget.dart';

class KaraokePlayerScreen extends StatefulWidget {
  final SongItem? song;
  final List<SongItem>? queue;

  const KaraokePlayerScreen({
    super.key,
    this.song,
    this.queue,
  });

  @override
  State<KaraokePlayerScreen> createState() => _KaraokePlayerScreenState();
}

class _KaraokePlayerScreenState extends State<KaraokePlayerScreen> {
  final VideokeFlowManager _flow = VideokeFlowManager();
  final AudioEngineService _audio = AudioEngineService();
  final SongCatalogService _catalog = SongCatalogService();

  int _positionMs = 0;
  int _durationMs = 0;
  Timer? _playbackTimer;

  List<Map<String, dynamic>> _timedLyrics = [];
  int _activeLyricIndex = -1;

  // BGV (Background Video) State
  VideoPlayerController? _bgvController;
  final List<String> _bgvVideos = [];
  int _currentBgvIndex = 0;
  bool _isBgvEnabled = true;

  @override
  void initState() {
    super.initState();
    _flow.addListener(_onFlowChanged);
    _catalog.addListener(_onFlowChanged);
    if (_catalog.songs.length <= 3) {
      _catalog.reloadCatalog();
    }
    _initBgv();

    // If song was passed and nothing is playing, play it
    if (widget.song != null && (_flow.currentSong == null || _flow.currentSong!.code != widget.song!.code)) {
      _flow.playSong(widget.song!);
    }

    _audio.onLyricsLoaded = (newLyrics) {
      if (mounted) {
        setState(() {
          _timedLyrics = newLyrics;
          _activeLyricIndex = -1;
        });
      }
    };

    _audio.getLyrics().then((lyrics) {
      if (mounted && lyrics.isNotEmpty) {
        setState(() {
          _timedLyrics = lyrics;
        });
      }
    });

    _playbackTimer = Timer.periodic(const Duration(milliseconds: 50), (_) async {
      if (mounted && _flow.isPlaying) {
        final pos = await _audio.getPosition();
        final dur = await _audio.getDuration();

        int activeIdx = -1;
        if (_timedLyrics.isNotEmpty) {
          for (int i = 0; i < _timedLyrics.length; i++) {
            final tMs = _timedLyrics[i]['timeMs'] as int? ?? 0;
            if (pos >= tMs) {
              activeIdx = i;
            } else {
              break;
            }
          }
        }

        setState(() {
          _positionMs = pos;
          _durationMs = dur;
          _activeLyricIndex = activeIdx;
        });
      }
    });
  }

  void _initBgv() {
    Future.microtask(() async {
      final candidateDirs = [
        '/sdcard/Download/KaraokeHub/content/bgv',
        '/sdcard/Download/karaokehub/content/bgv',
        '/sdcard/Download/KaraokeHub/content/bgv/Nature',
        '/sdcard/Download/KaraokeHub/content/bgv/Motion',
        '/sdcard/Download/KaraokeHub/content/bgv/3D',
        '/sdcard/Download/bgv',
        '/sdcard/Download/bvg',
        '/sdcard/KaraokeHub/bgv',
        '/storage/emulated/0/Download/KaraokeHub/content/bgv',
      ];

      for (final d in candidateDirs) {
        try {
          final dir = Directory(d);
          if (await dir.exists()) {
            final entities = await dir.list(recursive: false).toList();
            for (final entity in entities) {
              if (entity is File) {
                final lower = entity.path.toLowerCase();
                if (lower.endsWith('.mp4') || lower.endsWith('.mkv') || lower.endsWith('.avi')) {
                  if (!_bgvVideos.contains(entity.path)) {
                    _bgvVideos.add(entity.path);
                  }
                }
              }
            }
          }
        } catch (_) {}
      }

      if (mounted && _bgvVideos.isNotEmpty && _bgvController == null) {
        _loadBgvVideo(_bgvVideos.first);
      }
    });
  }

  void _loadBgvVideo(String path) {
    _bgvController?.dispose();
    _bgvController = VideoPlayerController.file(File(path))
      ..initialize().then((_) {
        if (mounted) {
          _bgvController?.setLooping(true);
          _bgvController?.setVolume(0.0); // Muted background video
          _bgvController?.play();
          setState(() {});
        }
      });
  }

  void _cycleNextBgv() {
    if (_bgvVideos.isEmpty) return;
    setState(() {
      _currentBgvIndex = (_currentBgvIndex + 1) % _bgvVideos.length;
    });
    _loadBgvVideo(_bgvVideos[_currentBgvIndex]);
  }

  void _toggleBgv() {
    setState(() {
      _isBgvEnabled = !_isBgvEnabled;
      if (!_isBgvEnabled) {
        _bgvController?.pause();
      } else {
        _bgvController?.play();
      }
    });
  }

  void _onFlowChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _flow.removeListener(_onFlowChanged);
    _catalog.removeListener(_onFlowChanged);
    _playbackTimer?.cancel();
    _bgvController?.dispose();
    super.dispose();
  }

  String _formatTime(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final remSec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${remSec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final current = _flow.currentSong ?? widget.song ?? const SongItem(
      code: "00000",
      title: "Videoke Standby",
      artist: "Ready to Sing",
      genre: "OPM",
    );

    return Scaffold(
      backgroundColor: const Color(0xFF030509),
      body: Stack(
        children: [
          // Background Video (BGV) Layer
          if (_isBgvEnabled && _bgvController != null && _bgvController!.value.isInitialized)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _bgvController!.value.size.width,
                  height: _bgvController!.value.size.height,
                  child: VideoPlayer(_bgvController!),
                ),
              ),
            ),

          // Dark Tint Gradient Overlay for Lyric Contrast
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _isBgvEnabled && _bgvController != null && _bgvController!.value.isInitialized
                      ? [
                          Colors.black.withOpacity(0.72),
                          Colors.black.withOpacity(0.50),
                          Colors.black.withOpacity(0.85),
                        ]
                      : [
                          const Color(0xFF030509),
                          const Color(0xFF080D1A),
                          const Color(0xFF030509),
                        ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Authentic Videoke Top HUD Bar
                _buildTopHudBar(current),

                const Spacer(),

                // Live Stage Lyric Prompter & Intro Countdown
                _buildStageLyricArea(current),

                const Spacer(),

                // Read-only Videoke Progress Bar (Non-draggable)
                if (_durationMs > 0) _buildReadOnlyProgressBar(),

                const SizedBox(height: 8),

                // Compact Videoke Tuning Bar (Key & Tempo)
                _buildTuningBar(),

                const SizedBox(height: 10),

                // Authentic Videoke Bottom Transport Controls
                _buildTransportControls(),

                const SizedBox(height: 10),
              ],
            ),
          ),

          // Authentic Videoke Scoring Fanfare Overlay
          if (_flow.isScoring && _flow.lastScore != null) _buildScoreOverlay(),
        ],
      ),
    );
  }

  // ==========================================
  // TOP HUD BAR (Iconic Videoke Header)
  // ==========================================
  Widget _buildTopHudBar(SongItem current) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0C101B).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          // Back Button
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 16),
            ),
          ),
          const SizedBox(width: 8),

          // Reserved Songs Badge (R: N) - Clickable to open Reserved Overlay
          InkWell(
            onTap: _showReservedSongsSheet,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _flow.queue.isNotEmpty ? const Color(0xFF003847) : const Color(0xFF161F30),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _flow.queue.isNotEmpty ? const Color(0xFF00F2FE) : Colors.white24,
                  width: 1.5,
                ),
                boxShadow: _flow.queue.isNotEmpty
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00F2FE).withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.format_list_numbered_rounded,
                    color: _flow.queue.isNotEmpty ? const Color(0xFF00F2FE) : Colors.white60,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'R: ${_flow.queue.length}',
                    style: TextStyle(
                      color: _flow.queue.isNotEmpty ? const Color(0xFF00F2FE) : Colors.white70,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Playing Marquee Banner
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _flow.isPlaying ? const Color(0xFF00E676) : const Color(0xFFFF2A6D),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _flow.isPlaying
                          ? '🎤 [${current.code}] ${current.title.toUpperCase()} • ${current.artist}'
                          : 'PAUSED: [${current.code}] ${current.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _flow.isPlaying ? const Color(0xFF00E676) : const Color(0xFFFF9800),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action Cluster: 🔢 SELECT (Dialpad) & 🔍 Search & BGV
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔢 SELECT (Keypad Dialpad Modal)
              InkWell(
                onTap: _showKeypadDialog,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6D00).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFF6D00), width: 1.2),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.dialpad_rounded, color: Color(0xFFFF9100), size: 13),
                      SizedBox(width: 4),
                      Text(
                        'SELECT',
                        style: TextStyle(
                          color: Color(0xFFFF9100),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // 🔍 Quick Search
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.search_rounded, color: Color(0xFF00F2FE), size: 18),
                tooltip: 'Search & Reserve',
                onPressed: _showSearchAndReserveDialog,
              ),

              // BGV Badge
              if (_bgvVideos.isNotEmpty)
                InkWell(
                  onTap: _cycleNextBgv,
                  onLongPress: _toggleBgv,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isBgvEnabled ? const Color(0xFF1E293B) : Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Icon(
                      _isBgvEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                      size: 13,
                      color: _isBgvEnabled ? const Color(0xFF00F2FE) : Colors.white38,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STAGE LYRICS AREA & INTRO BANNER
  // ==========================================
  Widget _buildStageLyricArea(SongItem current) {
    String prevText = "";
    String curText = "";
    String nextText = "";

    int countdownBeat = 0;
    String countdownUpcomingText = "";
    String countdownLabel = "GET READY TO SING";

    if (_timedLyrics.isNotEmpty) {
      final firstLyricTimeMs = _timedLyrics.first['timeMs'] as int? ?? 0;
      if (_activeLyricIndex < 0) {
        if (firstLyricTimeMs >= 3500) {
          if (_positionMs >= (firstLyricTimeMs - 4000) && _positionMs < firstLyricTimeMs) {
            final remainingMs = firstLyricTimeMs - _positionMs;
            countdownBeat = (remainingMs / 1000).ceil().clamp(1, 4);
            countdownUpcomingText = _timedLyrics.first['text'] as String? ?? "";
            countdownLabel = "GET READY TO SING";
          }
        } else if (firstLyricTimeMs > 400) {
          if (_positionMs < firstLyricTimeMs) {
            final step = firstLyricTimeMs / 4.0;
            countdownBeat = ((firstLyricTimeMs - _positionMs) / step).ceil().clamp(1, 4);
            countdownUpcomingText = _timedLyrics.first['text'] as String? ?? "";
            countdownLabel = "GET READY TO SING";
          }
        }
      } else if (_activeLyricIndex >= 0 && _activeLyricIndex + 1 < _timedLyrics.length) {
        final nextLyric = _timedLyrics[_activeLyricIndex + 1];
        final nextTimeMs = nextLyric['timeMs'] as int? ?? 0;
        final curTokens = (_timedLyrics[_activeLyricIndex]['tokens'] as List?) ?? [];
        final curEndMs = curTokens.isNotEmpty
            ? (curTokens.last['endMs'] as int? ?? _timedLyrics[_activeLyricIndex]['timeMs'] as int? ?? 0)
            : (_timedLyrics[_activeLyricIndex]['timeMs'] as int? ?? 0) + 2500;
        if (_positionMs >= curEndMs && (nextTimeMs - _positionMs) <= 4000 && (nextTimeMs - _positionMs) > 100) {
          final remainingMs = nextTimeMs - _positionMs;
          countdownBeat = (remainingMs / 1000).ceil().clamp(1, 4);
          countdownUpcomingText = nextLyric['text'] as String? ?? "";
          countdownLabel = "NEXT VERSE READY";
        }
      }
    } else if (_positionMs < 4000 && _flow.isPlaying) {
      final remainingMs = 4000 - _positionMs;
      countdownBeat = (remainingMs / 1000).ceil().clamp(1, 4);
      countdownUpcomingText = current.title;
      countdownLabel = "GET READY TO SING";
    }

    if (_timedLyrics.isEmpty) {
      prevText = "♪ VIDEOKE STAGE ACTIVE ♪";
      curText = current.title;
      nextText = "♪ ${current.artist} • Sing along with the melody ♪";
    } else if (_activeLyricIndex < 0) {
      prevText = "♪ INTRO ♪";
      curText = _timedLyrics.first['text'] as String? ?? "";
      nextText = _timedLyrics.length > 1 ? (_timedLyrics[1]['text'] as String? ?? "") : "";
    } else {
      prevText = _activeLyricIndex > 0 ? (_timedLyrics[_activeLyricIndex - 1]['text'] as String? ?? "") : "";
      curText = _timedLyrics[_activeLyricIndex]['text'] as String? ?? "";
      nextText = _activeLyricIndex + 1 < _timedLyrics.length ? (_timedLyrics[_activeLyricIndex + 1]['text'] as String? ?? "") : "♪ OUTRO ♪";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Intro Song Banner (shown during intro before lyrics)
          if (_activeLyricIndex < 0 && _flow.isPlaying) ...[
            Text(
              current.title.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(color: Colors.black, blurRadius: 10, offset: Offset(2, 2)),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              current.artist,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(color: Colors.black, blurRadius: 8, offset: Offset(1, 1)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ] else ...[
            // Previous lyric
            Text(
              prevText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.25),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Active Sing-Along Videoke Display or Countdown
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: countdownBeat > 0
                ? VideokeCountdownWidget(
                    key: ValueKey('countdown-$countdownBeat-$countdownLabel'),
                    count: countdownBeat,
                    upcomingLyric: countdownUpcomingText,
                    label: countdownLabel,
                  )
                : Container(
                    key: ValueKey('$_activeLyricIndex-$curText'),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00F2FE).withOpacity(0.12),
                          const Color(0xFF9B51E0).withOpacity(0.12),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF00F2FE).withOpacity(0.35)),
                    ),
                    child: _activeLyricIndex >= 0 && _activeLyricIndex < _timedLyrics.length
                        ? VideokeLyricWidget(
                            lyricLine: _timedLyrics[_activeLyricIndex],
                            positionMs: _positionMs,
                            highlightColor: const Color(0xFF00F2FE),
                            fontSize: 22.0,
                            outlineWidth: 4.0,
                          )
                        : (_timedLyrics.isNotEmpty
                            ? VideokeLyricWidget(
                                lyricLine: _timedLyrics.first,
                                positionMs: 0,
                                highlightColor: const Color(0xFF00F2FE),
                                fontSize: 22.0,
                                outlineWidth: 4.0,
                              )
                            : Text(
                                curText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                ),
                              )),
                  ),
          ),

          const SizedBox(height: 18),

          // Next lyric
          Text(
            nextText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // READ-ONLY PROGRESS BAR
  // ==========================================
  Widget _buildReadOnlyProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: (_positionMs / _durationMs).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00F2FE), Color(0xFF9B51E0)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF00F2FE),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTime(_positionMs),
                  style: const TextStyle(
                    color: Color(0xFF00F2FE),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'REALTIME VIDEOKE',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                Text(
                  _formatTime(_durationMs),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TUNING BAR (Key, Tempo, Cheer)
  // ==========================================
  Widget _buildTuningBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0C101B).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // KEY PITCH CONTROL
          Row(
            children: [
              const Text('KEY', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 11)),
              const SizedBox(width: 6),
              _buildCompactBtn('-', () => _flow.setPitch(_flow.pitch - 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  _flow.pitch > 0 ? '+${_flow.pitch}' : '${_flow.pitch}',
                  style: const TextStyle(color: Color(0xFF00F2FE), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              _buildCompactBtn('+', () => _flow.setPitch(_flow.pitch + 1)),
            ],
          ),

          Container(width: 1, height: 22, color: Colors.white12),

          // TEMPO SPEED CONTROL
          Row(
            children: [
              const Text('TEMPO', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 11)),
              const SizedBox(width: 6),
              _buildCompactBtn('-', () => _flow.setTempo(_flow.tempo - 0.1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${(_flow.tempo * 100).toInt()}%',
                  style: const TextStyle(color: Color(0xFF9B51E0), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              _buildCompactBtn('+', () => _flow.setTempo(_flow.tempo + 0.1)),
            ],
          ),

          Container(width: 1, height: 22, color: Colors.white12),

          // CHEER SFX
          InkWell(
            onTap: () => _audio.playSfx('cheer'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF2A6D).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF2A6D).withOpacity(0.5)),
              ),
              child: const Row(
                children: [
                  Text('👏', style: TextStyle(fontSize: 12)),
                  SizedBox(width: 4),
                  Text('CHEER', style: TextStyle(color: Color(0xFFFF2A6D), fontWeight: FontWeight.bold, fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BOTTOM TRANSPORT CONTROLS
  // ==========================================
  Widget _buildTransportControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Replay
          IconButton(
            icon: const Icon(Icons.replay_rounded, color: Colors.white70, size: 24),
            tooltip: 'Replay Song',
            onPressed: () => _flow.replay(),
          ),

          // Play/Pause Main Button
          InkWell(
            onTap: () => _flow.togglePlayPause(),
            borderRadius: BorderRadius.circular(40),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
                ),
              ),
              child: Icon(
                _flow.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.black,
                size: 28,
              ),
            ),
          ),

          // Stop
          IconButton(
            icon: const Icon(Icons.stop_rounded, color: Color(0xFFFF5252), size: 26),
            tooltip: 'Stop Playback',
            onPressed: () => _flow.stop(),
          ),

          // Next Song
          IconButton(
            icon: const Icon(Icons.skip_next_rounded, color: Color(0xFF00F2FE), size: 28),
            tooltip: 'Next Reserved Song',
            onPressed: () => _flow.next(),
          ),

          // RSV List Button (Quick Queue Sheet)
          InkWell(
            onTap: _showReservedSongsSheet,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.queue_music_rounded, color: Color(0xFFFFD700), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'RSV (${_flow.queue.length})',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // RESERVED SONGS OVERLAY MODAL SHEET
  // ==========================================
  void _showReservedSongsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final queue = _flow.queue;

            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                color: Color(0xFF0C101B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: Color(0xFF00F2FE), width: 2)),
              ),
              child: Column(
                children: [
                  // Sheet Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.playlist_play_rounded, color: Color(0xFF00F2FE), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'RESERVED SONGS (${queue.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white60),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12),

                  // Queue List or Empty State
                  Expanded(
                    child: queue.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.queue_music_rounded, color: Colors.white.withOpacity(0.15), size: 54),
                                const SizedBox(height: 10),
                                const Text(
                                  'NO SONGS RESERVED',
                                  style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Enter a song code using SELECT dialpad\nor search to queue songs for everyone!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white30, fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: queue.length,
                            separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                            itemBuilder: (context, index) {
                              final item = queue[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                leading: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: index == 0 ? const Color(0xFF00F2FE).withOpacity(0.2) : Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: index == 0 ? const Color(0xFF00F2FE) : Colors.white12,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '#${index + 1}',
                                    style: TextStyle(
                                      color: index == 0 ? const Color(0xFF00F2FE) : Colors.white60,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFD700).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.code,
                                        style: const TextStyle(
                                          color: Color(0xFFFFD700),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  item.artist,
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Play Now
                                    IconButton(
                                      icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF00E676), size: 24),
                                      tooltip: 'Play Immediately',
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _flow.playSong(item, fromQueue: true);
                                      },
                                    ),
                                    // Remove
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 20),
                                      tooltip: 'Remove',
                                      onPressed: () {
                                        _flow.removeFromQueue(item.code);
                                        setSheetState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 10),

                  // Bottom Action Buttons
                  Row(
                    children: [
                      // Clear All
                      if (queue.isNotEmpty)
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFF5252),
                              side: const BorderSide(color: Color(0xFFFF5252)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.clear_all_rounded, size: 18),
                            label: const Text('CLEAR ALL'),
                            onPressed: () {
                              _flow.clearQueue();
                              setSheetState(() {});
                            },
                          ),
                        ),
                      if (queue.isNotEmpty) const SizedBox(width: 12),

                      // Add by Dialpad
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00F2FE),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.dialpad_rounded, size: 18),
                          label: const Text('DIALPAD SELECT', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showKeypadDialog();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // AUTHENTIC VIDEOKE DIALPAD / KEYPAD MODAL
  // ==========================================
  SongItem? _findSongFromKeypad(String digits) {
    final clean = digits.trim();
    if (clean.isEmpty) return null;

    // 1. Exact string match
    for (final s in _catalog.songs) {
      if (s.code == clean) return s;
    }

    // 2. Numeric equality (e.g. typing "2482" matches "02482", typing "1" matches "00001")
    final qInt = int.tryParse(clean);
    if (qInt != null) {
      final padded = clean.padLeft(5, '0');
      for (final s in _catalog.songs) {
        if (s.code == padded) return s;
        final cInt = int.tryParse(s.code);
        if (cInt != null && cInt == qInt) return s;
      }
    }

    // 3. Prefix match on song code
    for (final s in _catalog.songs) {
      if (s.code.startsWith(clean)) return s;
    }

    // 4. Prefix match on numeric code without leading zeroes
    if (qInt != null) {
      final qStr = qInt.toString();
      for (final s in _catalog.songs) {
        final cInt = int.tryParse(s.code);
        if (cInt != null && cInt.toString().startsWith(qStr)) return s;
      }
    }

    return null;
  }

  List<SongItem> _findCandidatesFromKeypad(String digits) {
    final clean = digits.trim();
    if (clean.isEmpty) return [];
    final qInt = int.tryParse(clean);
    final qStr = qInt?.toString() ?? clean;
    final padded = clean.padLeft(5, '0');

    final results = <SongItem>[];
    for (final s in _catalog.songs) {
      if (s.code == clean || s.code == padded) {
        results.insert(0, s);
      } else if (s.code.startsWith(clean)) {
        results.add(s);
      } else if (qInt != null) {
        final cInt = int.tryParse(s.code);
        if (cInt != null && cInt.toString().startsWith(qStr)) {
          results.add(s);
        }
      }
      if (results.length >= 8) break;
    }
    return results;
  }

  void _showKeypadDialog() {
    String enteredDigits = "";
    SongItem? matchedSong;
    List<SongItem> candidates = [];

    // Ensure catalog is populated
    if (_catalog.songs.length <= 3) {
      _catalog.reloadCatalog();
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setKeypadState) {
            void updateInput(String digit) {
              if (enteredDigits.length < 6) {
                enteredDigits += digit;
                matchedSong = _findSongFromKeypad(enteredDigits);
                candidates = _findCandidatesFromKeypad(enteredDigits);
                setKeypadState(() {});
              }
            }

            void backspace() {
              if (enteredDigits.isNotEmpty) {
                enteredDigits = enteredDigits.substring(0, enteredDigits.length - 1);
                matchedSong = _findSongFromKeypad(enteredDigits);
                candidates = _findCandidatesFromKeypad(enteredDigits);
                setKeypadState(() {});
              }
            }

            void clearAll() {
              enteredDigits = "";
              matchedSong = null;
              candidates = [];
              setKeypadState(() {});
            }

            return Dialog(
              backgroundColor: const Color(0xFF0B101D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color(0xFFFF9100), width: 2),
              ),
              child: Container(
                width: 380,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with catalog song count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '🔢 SELECT SONG NUMBER (${_catalog.songs.length})',
                            style: const TextStyle(
                              color: Color(0xFFFF9100),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        if (_catalog.songs.length <= 3)
                          IconButton(
                            icon: const Icon(Icons.sync_rounded, color: Color(0xFF00F2FE), size: 18),
                            tooltip: 'Reload Catalog',
                            onPressed: () async {
                              await _catalog.reloadCatalog();
                              setKeypadState(() {
                                matchedSong = _findSongFromKeypad(enteredDigits);
                                candidates = _findCandidatesFromKeypad(enteredDigits);
                              });
                            },
                          ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Number Display Screen
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFF9100).withOpacity(0.5)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        enteredDigits.isEmpty ? "_ _ _ _ _" : enteredDigits,
                        style: TextStyle(
                          color: enteredDigits.isEmpty ? Colors.white24 : const Color(0xFFFFD700),
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Live Matched Song Preview Box
                    Container(
                      height: 56,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: matchedSong != null ? const Color(0xFF002230) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: matchedSong != null ? Border.all(color: const Color(0xFF00F2FE).withOpacity(0.5)) : null,
                      ),
                      child: matchedSong != null
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFD700),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        matchedSong!.code,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        matchedSong!.title.toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF00F2FE),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  matchedSong!.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  enteredDigits.isEmpty
                                      ? 'Type song number (e.g. 20554, 2482, 1)'
                                      : 'No match for code "$enteredDigits"',
                                  style: TextStyle(
                                    color: enteredDigits.isEmpty ? Colors.white38 : const Color(0xFFFF5252),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (enteredDigits.isNotEmpty)
                                  InkWell(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      _showSearchAndReserveDialog();
                                    },
                                    child: const Text(
                                      'Click here to Search by Title / Artist',
                                      style: TextStyle(color: Color(0xFF00F2FE), fontSize: 11, decoration: TextDecoration.underline),
                                    ),
                                  ),
                              ],
                            ),
                    ),

                    // Candidate matches bar (if user typed partial code)
                    if (candidates.length > 1) ...[
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 28,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: candidates.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (context, idx) {
                            final c = candidates[idx];
                            final isSelected = c.code == matchedSong?.code;
                            return InkWell(
                              onTap: () {
                                setKeypadState(() {
                                  enteredDigits = c.code;
                                  matchedSong = c;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF00F2FE) : const Color(0xFF161F30),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: isSelected ? Colors.white : Colors.white24),
                                ),
                                child: Text(
                                  '[${c.code}] ${c.title}',
                                  style: TextStyle(
                                    color: isSelected ? Colors.black : Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),

                    // 4x3 Arcade Dialpad Grid
                    Column(
                      children: [
                        _buildKeypadRow(['1', '2', '3'], updateInput),
                        const SizedBox(height: 8),
                        _buildKeypadRow(['4', '5', '6'], updateInput),
                        const SizedBox(height: 8),
                        _buildKeypadRow(['7', '8', '9'], updateInput),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _buildActionPadBtn('CLEAR', clearAll, color: const Color(0xFFFF5252))),
                            const SizedBox(width: 8),
                            Expanded(child: _buildDigitPadBtn('0', () => updateInput('0'))),
                            const SizedBox(width: 8),
                            Expanded(child: _buildActionPadBtn('⌫', backspace, color: const Color(0xFFFF9100))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons: ★ RESERVE vs ▶ PLAY
                    Row(
                      children: [
                        // RESERVE BUTTON
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003847),
                              foregroundColor: const Color(0xFF00F2FE),
                              side: const BorderSide(color: Color(0xFF00F2FE), width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                            label: const Text('RESERVE', style: TextStyle(fontWeight: FontWeight.w900)),
                            onPressed: matchedSong != null
                                ? () {
                                    _flow.reserve(matchedSong!);
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('✓ Reserved: [${matchedSong!.code}] ${matchedSong!.title}'),
                                        backgroundColor: const Color(0xFF003847),
                                      ),
                                    );
                                  }
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // PLAY NOW BUTTON
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E676),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded, size: 20),
                            label: const Text('PLAY NOW', style: TextStyle(fontWeight: FontWeight.w900)),
                            onPressed: matchedSong != null
                                ? () {
                                    Navigator.of(context).pop();
                                    _flow.playSong(matchedSong!);
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildKeypadRow(List<String> digits, Function(String) onDigit) {
    return Row(
      children: [
        for (int i = 0; i < digits.length; i++) ...[
          Expanded(child: _buildDigitPadBtn(digits[i], () => onDigit(digits[i]))),
          if (i < digits.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildDigitPadBtn(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF161F30),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActionPadBtn(String text, VoidCallback onTap, {required Color color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // QUICK SEARCH & RESERVE DIALOG
  // ==========================================
  void _showSearchAndReserveDialog() {
    String query = "";

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSearchState) {
            final filtered = query.trim().isEmpty
                ? _catalog.songs.take(20).toList()
                : _catalog.songs.where((s) {
                    final q = query.toLowerCase();
                    return s.title.toLowerCase().contains(q) ||
                        s.artist.toLowerCase().contains(q) ||
                        s.code.contains(q);
                  }).take(20).toList();

            return Dialog(
              backgroundColor: const Color(0xFF0C101B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF00F2FE), width: 1.5),
              ),
              child: Container(
                width: 420,
                height: 520,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search title, artist or code...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00F2FE)),
                        filled: true,
                        fillColor: Colors.black45,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setSearchState(() {
                          query = val;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No matching songs', style: TextStyle(color: Colors.white38)))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final s = filtered[i];
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    s.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text('${s.code} • ${s.artist}', style: const TextStyle(color: Colors.white54)),
                                  trailing: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF003847),
                                      foregroundColor: const Color(0xFF00F2FE),
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                    ),
                                    child: const Text('RESERVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      _flow.reserve(s);
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('✓ Reserved: [${s.code}] ${s.title}'),
                                          backgroundColor: const Color(0xFF003847),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // SCORING OVERLAY
  // ==========================================
  Widget _buildScoreOverlay() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        color: Colors.black.withOpacity(0.8),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'YOUR SCORE',
              style: TextStyle(
                color: Color(0xFF00F2FE),
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${_flow.lastScore}',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 90,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _flow.lastScore! >= 95
                  ? '🌟 EXCELLENT SINGER! 🌟'
                  : _flow.lastScore! >= 85
                      ? '👏 GREAT PERFORMANCE! 👏'
                      : 'GOOD TRY! KEEP SINGING!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _flow.queue.isNotEmpty
                  ? 'Advancing to next reserved song [${_flow.queue.first.code}] ${_flow.queue.first.title}...'
                  : 'Queue empty. Returning to videoke standby stage...',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactBtn(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: const Color(0xFF161F30),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white12),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }
}
