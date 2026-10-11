import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/song_item.dart';
import '../services/audio_engine_service.dart';
import '../services/videoke_flow_manager.dart';

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

    _playbackTimer = Timer.periodic(const Duration(milliseconds: 200), (_) async {
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
    final candidateDirs = [
      '/sdcard/Download/KaraokeHub/content/bgv',
      '/sdcard/Download/karaokehub/content/bgv',
      '/sdcard/Download/KaraokeHub/content/bgv/Nature',
      '/sdcard/Download/KaraokeHub/content/bgv/Motion',
      '/sdcard/Download/KaraokeHub/content/bgv/3D',
      '/storage/emulated/0/Download/KaraokeHub/content/bgv',
      '/storage/emulated/0/Download/karaokehub/content/bgv',
      '/sdcard/Download/bgv',
      '/sdcard/Download/bvg',
      '/storage/emulated/0/Download/bgv',
      '/storage/emulated/0/Download/bvg',
      '/sdcard/Download/VideoDownloader/Facebook',
      '/storage/emulated/0/Download/VideoDownloader/Facebook',
      '/sdcard/Download',
      '/storage/emulated/0/Download',
      '/sdcard/KaraokeHub/bgv',
    ];

    for (final d in candidateDirs) {
      try {
        final dir = Directory(d);
        if (dir.existsSync()) {
          final files = dir.listSync(recursive: true).whereType<File>().where((f) {
            final lower = f.path.toLowerCase();
            return lower.endsWith('.mp4') || lower.endsWith('.mkv') || lower.endsWith('.avi');
          }).toList();
          for (final f in files) {
            if (!_bgvVideos.contains(f.path)) {
              _bgvVideos.add(f.path);
            }
          }
        }
      } catch (_) {}
    }

    if (_bgvVideos.isNotEmpty) {
      _loadBgvVideo(_bgvVideos.first);
    }
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
      artist: "Ready",
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
                          Colors.black.withOpacity(0.70),
                          Colors.black.withOpacity(0.55),
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

          // Background Cyber Aesthetic Ambient Glow
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00F2FE).withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            right: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF2A6D).withOpacity(0.08),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Stage Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _flow.isPlaying ? const Color(0xFF00F2FE) : const Color(0xFFFF2A6D),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _flow.isPlaying ? 'LIVE PROMPTER' : 'PAUSED',
                                style: TextStyle(
                                  color: _flow.isPlaying ? const Color(0xFF00F2FE) : const Color(0xFFFF2A6D),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'QUEUE: ${_flow.queue.length}',
                            style: const TextStyle(color: Colors.white38, fontSize: 10),
                          ),
                        ],
                      ),
                      // BGV and Song Code Header Cluster
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_bgvVideos.isNotEmpty)
                            InkWell(
                              onTap: _cycleNextBgv,
                              onLongPress: _toggleBgv,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _isBgvEnabled ? const Color(0xFF1E293B) : Colors.black45,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _isBgvEnabled ? const Color(0xFF00F2FE).withOpacity(0.4) : Colors.white12,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isBgvEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                                      size: 13,
                                      color: _isBgvEnabled ? const Color(0xFF00F2FE) : Colors.white38,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'BGV ${_currentBgvIndex + 1}/${_bgvVideos.length}',
                                      style: TextStyle(
                                        color: _isBgvEnabled ? Colors.white : Colors.white38,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // SoundFont Status Indicator Badge
                          FutureBuilder<Map<String, dynamic>>(
                            future: _audio.getSynthStatus(),
                            builder: (context, snapshot) {
                              final data = snapshot.data ?? {};
                              final active = data['soundfontActive'] == true;
                              return Tooltip(
                                message: active ? 'SoundFont SF2 Active: ${data['soundfontPath']}' : 'Standard Synth Active',
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: active ? const Color(0xFF0D3220) : const Color(0xFF2B1D1D),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: active ? const Color(0xFF00E676).withOpacity(0.5) : const Color(0xFFFF5252).withOpacity(0.4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.piano_rounded,
                                        size: 12,
                                        color: active ? const Color(0xFF00E676) : const Color(0xFFFF5252),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        active ? 'SF2' : 'MIDI',
                                        style: TextStyle(
                                          color: active ? const Color(0xFF00E676) : const Color(0xFFFF5252),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF101624),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Text(
                              current.code,
                              style: const TextStyle(
                                color: Color(0xFF00F2FE),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Song Title & Singer Marquee
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        current.title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        current.artist,
                        style: const TextStyle(
                          color: Color(0xFF00F2FE),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Live Kinetic Lyric Prompter
                Builder(
                  builder: (context) {
                    String prevText = "";
                    String curText = "";
                    String nextText = "";

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
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        children: [
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

                          // Active Sing-Along Kinetic Highlight
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              key: ValueKey('$_activeLyricIndex-$curText'),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF00F2FE).withOpacity(0.15),
                                    const Color(0xFF9B51E0).withOpacity(0.15),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF00F2FE).withOpacity(0.3)),
                              ),
                              child: Text(
                                curText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF00F2FE),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                ),
                              ),
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
                  },
                ),

                const Spacer(),

                // Playback progress bar
                if (_durationMs > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            activeTrackColor: const Color(0xFF00F2FE),
                            inactiveTrackColor: Colors.white12,
                            thumbColor: const Color(0xFF00F2FE),
                          ),
                          child: Slider(
                            value: _positionMs.clamp(0, _durationMs).toDouble(),
                            max: _durationMs.toDouble(),
                            onChanged: (val) {
                              _audio.seekTo(val.toInt());
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatTime(_positionMs), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              Text(_formatTime(_durationMs), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 10),

                // Authentic Videoke Tuning Panel (Key / Tempo)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C101B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // KEY PITCH CONTROL (-12 to +12)
                      Row(
                        children: [
                          const Text('KEY', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(width: 8),
                          _buildStepBtn('-', () => _flow.setPitch(_flow.pitch - 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              _flow.pitch > 0 ? '+${_flow.pitch}' : '${_flow.pitch}',
                              style: const TextStyle(color: Color(0xFF00F2FE), fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          _buildStepBtn('+', () => _flow.setPitch(_flow.pitch + 1)),
                        ],
                      ),

                      Container(width: 1, height: 28, color: Colors.white12),

                      // TEMPO SPEED CONTROL (0.5 to 1.5)
                      Row(
                        children: [
                          const Text('TEMPO', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(width: 8),
                          _buildStepBtn('-', () => _flow.setTempo(_flow.tempo - 0.1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '${(_flow.tempo * 100).toInt()}%',
                              style: const TextStyle(color: Color(0xFF9B51E0), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          _buildStepBtn('+', () => _flow.setTempo(_flow.tempo + 0.1)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Bottom Transport Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Previous (History)
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, color: Colors.white70, size: 30),
                        tooltip: 'Previous Song',
                        onPressed: _flow.history.isNotEmpty ? () => _flow.previous() : null,
                      ),

                      // Replay
                      IconButton(
                        icon: const Icon(Icons.replay_rounded, color: Colors.white70, size: 26),
                        tooltip: 'Replay Song',
                        onPressed: () => _flow.replay(),
                      ),

                      // Play/Pause Main Button
                      InkWell(
                        onTap: () => _flow.togglePlayPause(),
                        borderRadius: BorderRadius.circular(40),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
                            ),
                          ),
                          child: Icon(
                            _flow.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.black,
                            size: 32,
                          ),
                        ),
                      ),

                      // Stop
                      IconButton(
                        icon: const Icon(Icons.stop_rounded, color: Colors.white70, size: 30),
                        tooltip: 'Stop Playback',
                        onPressed: () => _flow.stop(),
                      ),

                      // Next Song
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, color: Color(0xFF00F2FE), size: 32),
                        tooltip: 'Next Reserved Song',
                        onPressed: () => _flow.next(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),

          // Authentic Videoke Scoring Fanfare Overlay
          if (_flow.isScoring && _flow.lastScore != null)
            BackdropFilter(
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
                    const Text(
                      'Advancing to next song in queue...',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepBtn(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF141C2E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
