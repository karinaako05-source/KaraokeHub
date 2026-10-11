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

class _KaraokePlayerScreenState extends State<KaraokePlayerScreen> {
  final AudioEngineService _audio = AudioEngineService();
  late SongItem _currentSong;
  late List<SongItem> _remainingQueue;

  bool _isPlaying = true;
  int _currentPitch = 0;
  double _currentTempo = 1.0;
  int _score = 92;

  // Real videoke classic lyric sequence
  final List<String> _lyrics = [
    "♪ INTRO ♪",
    "Kamukha mo si Paraluman",
    "Nung tayo ay bata pa",
    "At ang galing-galing mong sumayaw",
    "Mapa-Boogie man o Cha-Cha",
    "Ngunit ang paborito ay ang pagsayaw mo ng El Bimbo",
    "Habang nakatitig sa iyong mga mata",
    "Magkahawak ang ating kamay",
    "At walang kamalay-malay",
    "Na ang puso ko'y sa 'yo pala naghihintay",
    "♪ INSTRUMENTAL INTERLUDE ♪",
  ];

  int _activeLyricIndex = 0;
  Timer? _lyricTimer;
  Timer? _scoreTimer;

  @override
  void initState() {
    super.initState();
    _currentSong = widget.song;
    _remainingQueue = List.from(widget.queue);
    
    // Play real audio if available
    _audio.playSong(_currentSong.filePath);

    // Smooth videoke prompter loop
    _lyricTimer = Timer.periodic(const Duration(milliseconds: 3000), (timer) {
      if (_isPlaying && mounted) {
        setState(() {
          _activeLyricIndex = (_activeLyricIndex + 1) % _lyrics.length;
        });
      }
    });

    _scoreTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_isPlaying && mounted) {
        setState(() {
          _score = 88 + (_activeLyricIndex * 3) % 12;
        });
      }
    });
  }

  @override
  void dispose() {
    _lyricTimer?.cancel();
    _scoreTimer?.cancel();
    _audio.stop();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() => _isPlaying = !_isPlaying);
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
      _audio.playSong(_currentSong.filePath);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _adjustPitch(int delta) {
    setState(() => _currentPitch += delta);
    _audio.setPitch(_currentPitch);
  }

  void _adjustTempo(double delta) {
    setState(() => _currentTempo = (_currentTempo + delta).clamp(0.7, 1.4));
    _audio.setTempo(_currentTempo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060A),
      body: Stack(
        children: [
          // 1. High-Tech Cyber Videoke Background Stage
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.1),
                  radius: 1.3,
                  colors: [
                    Color(0xFF141C30),
                    Color(0xFF070B14),
                    Color(0xFF020306),
                  ],
                ),
              ),
            ),
          ),

          // Glowing Neon Ambient Aura
          Positioned(
            top: 80,
            left: 20,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00F2FE).withOpacity(0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox(),
              ),
            ),
          ),

          // 2. Main Videoke Console Overlay
          SafeArea(
            child: Column(
              children: [
                // Top Videoke Header Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 6),
                      // Song Number Badge & Title
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F2FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _currentSong.code,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentSong.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _currentSong.artist,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Videoke Score Gauge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131A2A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF9B51E0), width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.score_rounded, color: Color(0xFF9B51E0), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'SCORE: ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // 3. Videoke High-Contrast Lyrics Prompter
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
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          margin: EdgeInsets.symmetric(vertical: isActive ? 12 : 6),
                          child: Text(
                            _lyrics[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isActive ? 26 : 17,
                              fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                              color: isActive
                                  ? const Color(0xFF00F2FE)
                                  : Colors.white.withOpacity(0.35 - (distance * 0.1)),
                              shadows: isActive
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF00F2FE).withOpacity(0.8),
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

                // 4. Modern Frosted Videoke Remote Keypad & Controls
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101624).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Videoke Key & Tempo Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // KEY
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_rounded, color: Colors.white70),
                                onPressed: () => _adjustPitch(-1),
                              ),
                              Text(
                                "KEY: ${_currentPitch >= 0 ? '+$_currentPitch' : _currentPitch}",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_rounded, color: Colors.white70),
                                onPressed: () => _adjustPitch(1),
                              ),
                            ],
                          ),
                          Container(width: 1, height: 20, color: Colors.white12),
                          // TEMPO
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.fast_rewind_rounded, color: Colors.white70),
                                onPressed: () => _adjustTempo(-0.05),
                              ),
                              Text(
                                "TEMPO ${(_currentTempo * 100).toInt()}%",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              IconButton(
                                icon: const Icon(Icons.fast_forward_rounded, color: Colors.white70),
                                onPressed: () => _adjustTempo(0.05),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Videoke Transport Deck
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay_circle_filled_rounded, color: Colors.white70, size: 32),
                            tooltip: 'Restart Song',
                            onPressed: () {
                              setState(() => _activeLyricIndex = 0);
                              _audio.play();
                            },
                          ),
                          // Primary Play/Pause Orb
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
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded, color: Colors.white70, size: 36),
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
