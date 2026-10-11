import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
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

  final List<String> _lyrics = [
    "♪ VIDEOKE STAGE ACTIVE ♪",
    "Sing along with the melody!",
    "Kamukha mo si Paraluman nung tayo ay bata pa",
    "At ang galing-galing mong sumayaw, mapa-Boogie man o Cha-Cha",
    "Ngunit ang paborito ay ang pagsayaw mo ng El Bimbo",
    "Habang nakatitig sa iyong mga mata",
    "Magkahawak ang ating kamay, at walang kamalay-malay",
    "Na ang puso ko'y sa 'yo pala naghihintay",
    "♪ INTERLUDE / SOLO ♪",
    "La la la la, la la la, la la la...",
  ];

  int _activeLyricIndex = 0;
  Timer? _lyricTimer;

  @override
  void initState() {
    super.initState();
    _flow.addListener(_onFlowChanged);

    // If song was passed and nothing is playing, play it
    if (widget.song != null && (_flow.currentSong == null || _flow.currentSong!.code != widget.song!.code)) {
      _flow.playSong(widget.song!);
    }

    _lyricTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (_flow.isPlaying && mounted) {
        setState(() {
          _activeLyricIndex = (_activeLyricIndex + 1) % _lyrics.length;
        });
      }
    });

    _playbackTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (mounted && _flow.isPlaying) {
        final pos = await _audio.getPosition();
        final dur = await _audio.getDuration();
        setState(() {
          _positionMs = pos;
          _durationMs = dur;
        });
      }
    });
  }

  void _onFlowChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _flow.removeListener(_onFlowChanged);
    _lyricTimer?.cancel();
    _playbackTimer?.cancel();
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      // Upcoming lyric
                      Text(
                        _lyrics[(_activeLyricIndex + _lyrics.length - 1) % _lyrics.length],
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
                          key: ValueKey(_activeLyricIndex),
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
                            _lyrics[_activeLyricIndex],
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
                        _lyrics[(_activeLyricIndex + 1) % _lyrics.length],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
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
