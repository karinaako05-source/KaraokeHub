import 'karaoke_player_screen.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/song_item.dart';
import '../services/audio_engine_service.dart';
import '../widgets/song_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final AudioEngineService _audio = AudioEngineService();

  String _selectedGenre = 'ALL';
  SongItem? _currentlyPlaying;
  final List<SongItem> _queue = [];

  final List<SongItem> _sampleSongs = const [
    SongItem(code: "71001", title: "Ang Huling El Bimbo", artist: "Eraserheads", genre: "OPM"),
    SongItem(code: "71002", title: "With a Smile", artist: "Eraserheads", genre: "OPM"),
    SongItem(code: "71003", title: "214", artist: "Rivermaya", genre: "OPM"),
    SongItem(code: "71004", title: "Kisapmata", artist: "Rivermaya", genre: "OPM"),
    SongItem(code: "71005", title: "Jopay", artist: "Mayonnaise", genre: "ROCK"),
    SongItem(code: "71006", title: "Noypi", artist: "Bamboo", genre: "ROCK"),
    SongItem(code: "71007", title: "Beer", artist: "Itchyworms", genre: "OPM"),
    SongItem(code: "71008", title: "Buwan", artist: "juan karlos", genre: "POP"),
    SongItem(code: "71009", title: "Kathang Isip", artist: "Ben&Ben", genre: "ACOUSTIC"),
    SongItem(code: "71010", title: "Araw-Araw", artist: "Ben&Ben", genre: "ACOUSTIC"),
    SongItem(code: "71011", title: "Torete", artist: "Moonstar88", genre: "OPM"),
    SongItem(code: "71012", title: "Bakit Ba Ikaw", artist: "Michael Pangilinan", genre: "POP"),
  ];

  @override
  void initState() {
    super.initState();
    _audio.initEngine();
  }

  List<SongItem> get _filteredSongs {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _sampleSongs.where((s) {
      final matchesGenre = _selectedGenre == 'ALL' || s.genre == _selectedGenre;
      final matchesQuery = q.isEmpty ||
          s.title.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q) ||
          s.code.contains(q);
      return matchesGenre && matchesQuery;
    }).toList();
  }

  void _playSong(SongItem song) {
    setState(() {
      _currentlyPlaying = song;
    });
    _audio.play();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => KaraokePlayerScreen(
          song: song,
          queue: _queue,
        ),
      ),
    );
  }

  void _addToQueue(SongItem song) {
    setState(() {
      _queue.add(song);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF161B26),
        content: Text("Added to Queue (#${_queue.length}): ${song.title}"),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final genres = ['ALL', 'OPM', 'ROCK', 'POP', 'ACOUSTIC'];

    return Scaffold(
      backgroundColor: const Color(0xFF090B10),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.mic_external_on_rounded, color: Colors.black, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KARAOKEHUB',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'NEXT-GEN PRO EDITION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: Color(0xFF00F2FE),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Queue Count Indicator
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.queue_music_rounded, color: Colors.white70),
                        onPressed: () => _showQueueModal(context),
                      ),
                      if (_queue.isNotEmpty)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF9B51E0),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${_queue.length}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF131722),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search title, artist or 5-digit number...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00F2FE)),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Genre Chips
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: genres.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final g = genres[idx];
                  final isSelected = _selectedGenre == g;
                  return ChoiceChip(
                    label: Text(g),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedGenre = g);
                    },
                    selectedColor: const Color(0xFF00F2FE),
                    backgroundColor: const Color(0xFF131722),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF00F2FE) : Colors.white.withOpacity(0.08),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Song List
            Expanded(
              child: ListView.builder(
                itemCount: _filteredSongs.length,
                itemBuilder: (context, index) {
                  final song = _filteredSongs[index];
                  return SongTile(
                    song: song,
                    onPlay: () => _playSong(song),
                    onQueue: () => _addToQueue(song),
                  );
                },
              ),
            ),

            // Bottom Mini Player Bar
            if (_currentlyPlaying != null)
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => KaraokePlayerScreen(
                        song: _currentlyPlaying!,
                        queue: _queue,
                      ),
                    ),
                  );
                },
                child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B2233), Color(0xFF131722)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00F2FE).withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F2FE).withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00F2FE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.music_note_rounded, color: Colors.black, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentlyPlaying!.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            _currentlyPlaying!.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.exposure_minus_1_rounded, color: Colors.white70),
                      tooltip: 'Key -1',
                      onPressed: () => _audio.setPitch(-1),
                    ),
                    IconButton(
                      icon: const Icon(Icons.exposure_plus_1_rounded, color: Colors.white70),
                      tooltip: 'Key +1',
                      onPressed: () => _audio.setPitch(1),
                    ),
                    IconButton(
                      icon: const Icon(Icons.pause_circle_filled_rounded, color: Color(0xFF00F2FE), size: 36),
                      onPressed: () {
                        _audio.pause();
                        setState(() => _currentlyPlaying = null);
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showQueueModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121620),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Song Queue',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _queue.clear());
                      setModalState(() {});
                    },
                    child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
              const Divider(color: Colors.white12),
              Expanded(
                child: _queue.isEmpty
                    ? const Center(
                        child: Text('No songs in queue yet.', style: TextStyle(color: Colors.white54)),
                      )
                    : ListView.builder(
                        itemCount: _queue.length,
                        itemBuilder: (context, idx) {
                          final song = _queue[idx];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF9B51E0),
                              radius: 14,
                              child: Text('${idx + 1}', style: const TextStyle(fontSize: 12)),
                            ),
                            title: Text(song.title),
                            subtitle: Text(song.artist),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                              onPressed: () {
                                setState(() => _queue.removeAt(idx));
                                setModalState(() {});
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
