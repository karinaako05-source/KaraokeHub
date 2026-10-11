import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/song_item.dart';
import '../services/audio_engine_service.dart';

class KaraokePlayerScreen extends StatefulWidget {
  final SongItem song;
  final List<SongItem> queue;

  const KaraokePlayerScreen({
    super.key,
    required this.song,
    required this.queue,
  });

  @override
  State<KaraokePlayerScreen> createState() => _KaraokePlayerScreenState();
}

class _KaraokePlayerScreenState extends State<KaraokePlayerScreen> with SingleTickerProviderStateMixin {
  final AudioEngineService _audio = AudioEngineService();
  late SongItem _currentSong;
  late List<SongItem> _remainingQueue;

  bool _isPlaying = true;
  int _currentPitch = 0;
  double _currentTempo = 1.0;
  int _score = 88;

  // Simulated synchronized lyric lines
  final List<String> _lyrics = [
    "Kamukha mo si Paraluman",
    "Nung tayo ay bata pa",
    "At ang galing-galing mong sumayaw",
    "Mapa-Boogie man o Cha-Cha",
    "Ngunit ang paborito ay ang pagsayaw mo ng El Bimbo",
    "Habang nakatitig sa iyong mga mata",
    "Magkahawak ang ating kamay",
    "At walang kamalay-malay",
    "Na ang puso ko'y sa 'yo pala naghihintay",
  ];

  int _activeLyricIndex = 0;
  Timer? _lyricTimer;
  Timer? _scoreTimer;

  @override
  void initState() {
    super.initState();
    _currentSong = widget.song;
    _remainingQueue = List.from(widget.queue);
    _audio.play();

    // Smooth auto-advancing karaoke lyric prompter
    _lyricTimer = Timer.periodic(const Duration(milliseconds: 3200), (timer) {
      if (_isPlaying && mounted) {
        setState(() {
          _activeLyricIndex = (_activeLyricIndex + 1) % _lyrics.length;
        });
      }
    });

    // Dynamic singing score fluctuation simulation
    _scoreTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_isPlaying && mounted) {
        setState(() {
          _score = 85 + (_activeLyricIndex * 2) % 15;
        });
      }
    });
  }

  @override
  void dispose() {
    _lyricTimer?.cancel();
    _scoreTimer?.cancel();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    if (_isPlaying) {
      _audio.play();
    } else {
      _audio.pause();
    }
  }

  void _nextSong() {
    if (_remainingQueue.isNotEmpty) {
      setState(() {
        _currentSong = _remainingQueue.removeAt(0);
        _activeLyricIndex = 0;
      });
      _audio.play();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _adjustPitch(int delta) {
    setState(() {
      _currentPitch += delta;
    });
    _audio.setPitch(_currentPitch);
  }

  void _adjustTempo(double delta) {
    setState(() {
      _currentTempo = (_currentTempo + delta).clamp(0.7, 1.4);
    });
    _audio.setTempo(_currentTempo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      body: Stack(
        children: [
          // Dynamic Animated Visualizer / Background Stage
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 1.2,
                  colors: [
                    Color(0xFF191B2E),
                    Color(0xFF0A0C14),
                    Color(0xFF040608),
                  ],
                ),
              ),
            ),
          ),

          // Floating Background Glow Orbs
          Positioned(
            top: 120,
            left: 30,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00F2FE).withOpacity(0.06),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: const SizedBox(),
              ),
            ),
          ),
          Positioned(
            bottom: 180,
            right: 40,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF9B51E0).withOpacity(0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: const SizedBox(),
              ),
            ),
          ),

          // Main Interactive Foreground
          SafeArea(
            child: Column(
              children: [
                // Top Header (Back, Song Title/Code, Realtime Score Badge)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentSong.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "${_currentSong.code} • ${_currentSong.artist}",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF00F2FE),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Real-time Singing Score Display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9B51E0), Color(0xFF6B21A8)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9B51E0).withOpacity(0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '$_score',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // Center Stage: Kinetic Apple-Music Style Karaoke Lyrics
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_lyrics.length, (index) {
                        final distance = (index - _activeLyricIndex).abs();
                        if (distance > 2) return const SizedBox.shrink();

                        final isActive = index == _activeLyricIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          margin: EdgeInsets.symmetric(vertical: isActive ? 14 : 8),
                          child: Text(
                            _lyrics[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isActive ? 24 : 16,
                              fontWeight: isActive ? FontWeight.w900 : FontWeight.w500,
                              color: isActive
                                  ? const Color(0xFF00F2FE)
                                  : Colors.white.withOpacity(0.35 - (distance * 0.1)),
                              shadows: isActive
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF00F2FE).withOpacity(0.6),
                                        blurRadius: 18,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // Floating Frosted Control Deck (Key, Tempo, Next, Play/Pause)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141824).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Pitch & Tempo Adjusters
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Pitch / Key Adjuster
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.white70),
                                onPressed: () => _adjustPitch(-1),
                              ),
                              Text(
                                "KEY: ${_currentPitch >= 0 ? '+$_currentPitch' : _currentPitch}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white70),
                                onPressed: () => _adjustPitch(1),
                              ),
                            ],
                          ),
                          Container(width: 1, height: 24, color: Colors.white12),
                          // Tempo Adjuster
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.fast_rewind_rounded, color: Colors.white70),
                                onPressed: () => _adjustTempo(-0.05),
                              ),
                              Text(
                                "${(_currentTempo * 100).toInt()}%",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              IconButton(
                                icon: const Icon(Icons.fast_forward_rounded, color: Colors.white70),
                                onPressed: () => _adjustTempo(0.05),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Main Playback Transport
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay_rounded, color: Colors.white70, size: 28),
                            tooltip: 'Restart Song',
                            onPressed: () {
                              setState(() => _activeLyricIndex = 0);
                              _audio.play();
                            },
                          ),
                          // Big Play / Pause CTA
                          GestureDetector(
                            onTap: _togglePlayPause,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
                                ),
                              ),
                              child: Icon(
                                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.black,
                                size: 36,
                              ),
                            ),
                          ),
                          // Next Song in Queue Button
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded, color: Colors.white70, size: 32),
                            tooltip: 'Next Song',
                            onPressed: _nextSong,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
