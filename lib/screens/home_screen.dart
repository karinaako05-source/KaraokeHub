import 'dart:io';
import 'package:flutter/material.dart';
import '../models/song_item.dart';
import '../services/audio_engine_service.dart';
import '../widgets/song_tile.dart';
import 'karaoke_player_screen.dart';

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
  final List<SongItem> _songCatalog = [];

  // Digital Keypad buffer for 5-digit videoke song code
  String _keypadInput = '';

  @override
  void initState() {
    super.initState();
    _audio.initEngine();
    _loadInitialSongs();
  }

  void _loadInitialSongs() {
    // 1. Built-in Videoke Classic Hits
    final defaultHits = [
      const SongItem(code: "71001", title: "Ang Huling El Bimbo", artist: "Eraserheads", genre: "OPM"),
      const SongItem(code: "71002", title: "With a Smile", artist: "Eraserheads", genre: "OPM"),
      const SongItem(code: "71003", title: "214", artist: "Rivermaya", genre: "OPM"),
      const SongItem(code: "71004", title: "Kisapmata", artist: "Rivermaya", genre: "OPM"),
      const SongItem(code: "71005", title: "Jopay", artist: "Mayonnaise", genre: "ROCK"),
      const SongItem(code: "71006", title: "Noypi", artist: "Bamboo", genre: "ROCK"),
      const SongItem(code: "71007", title: "Beer", artist: "Itchyworms", genre: "OPM"),
      const SongItem(code: "71008", title: "Buwan", artist: "juan karlos", genre: "POP"),
    ];
    _songCatalog.addAll(defaultHits);

    // 2. Scan device /sdcard/Download folder for real media files
    try {
      final dir = Directory('/sdcard/Download');
      if (dir.existsSync()) {
        final files = dir.listSync();
        int customCode = 80001;
        for (var entity in files) {
          if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
            final fileName = entity.uri.pathSegments.last.replaceAll('.mp3', '');
            final parts = fileName.split('-');
            final artist = parts.isNotEmpty ? parts[0].trim() : 'Local Artist';
            final title = parts.length > 1 ? parts[1].trim() : fileName;
            
            _songCatalog.add(
              SongItem(
                code: "$customCode",
                title: title,
                artist: artist,
                genre: "LOCAL",
                filePath: entity.path,
              ),
            );
            customCode++;
          }
        }
      }
    } catch (_) {}
    setState(() {});
  }

  List<SongItem> get _filteredSongs {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _songCatalog.where((s) {
      final matchesGenre = _selectedGenre == 'ALL' || s.genre == _selectedGenre;
      final matchesQuery = q.isEmpty ||
          s.title.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q) ||
          s.code.contains(q);
      return matchesGenre && matchesQuery;
    }).toList();
  }

  void _playSong(SongItem song) {
    setState(() => _currentlyPlaying = song);
    _audio.playSong(song.filePath);
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
    setState(() => _queue.add(song));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF141926),
        content: Text("Reserved (#${_queue.length}): ${song.code} - ${song.title}"),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _onKeypadPress(String digit) {
    if (_keypadInput.length < 5) {
      setState(() => _keypadInput += digit);
      if (_keypadInput.length == 5) {
        final found = _songCatalog.firstWhere(
          (s) => s.code == _keypadInput,
          orElse: () => SongItem(code: _keypadInput, title: "Unknown Song", artist: "Unknown", genre: "CUSTOM"),
        );
        _addToQueue(found);
        _keypadInput = '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final genres = ['ALL', 'OPM', 'ROCK', 'POP', 'LOCAL'];

    return Scaffold(
      backgroundColor: const Color(0xFF06080E),
      body: SafeArea(
        child: Column(
          children: [
            // Top Modern Videoke Console Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        'KARAOKEHUB NEXT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'MODERN VIDEOKE CONSOLE',
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
                  // Remote Keypad Button
                  IconButton(
                    icon: const Icon(Icons.dialpad_rounded, color: Color(0xFF00F2FE)),
                    tooltip: 'Digital Videoke Keypad',
                    onPressed: () => _showKeypadModal(context),
                  ),
                  // Queue Button
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
                  color: const Color(0xFF101420),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search title, artist or 5-digit song number...',
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
            const SizedBox(height: 10),

            // Category Chips
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
                    backgroundColor: const Color(0xFF101420),
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

            // Song Catalog
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
                    color: const Color(0xFF141A28),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF00F2FE).withOpacity(0.35)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F2FE).withOpacity(0.15),
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
                              "${_currentlyPlaying!.code} • ${_currentlyPlaying!.artist}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_full_rounded, color: Color(0xFF00F2FE)),
                        tooltip: 'Open Full Videoke Stage',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => KaraokePlayerScreen(
                                song: _currentlyPlaying!,
                                queue: _queue,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showKeypadModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0C101A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setKeypadState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ENTER VIDEOKE NUMBER (5 DIGITS)',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              // Code Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF141926),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF00F2FE).withOpacity(0.5)),
                ),
                child: Text(
                  _keypadInput.isEmpty ? "-----" : _keypadInput.padRight(5, '-'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF00F2FE),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Numpad 0-9
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 1; i <= 9; i++)
                    _buildNumpadBtn('', () {
                      _onKeypadPress('');
                      setKeypadState(() {});
                    }),
                  _buildNumpadBtn('CLEAR', () {
                    setState(() => _keypadInput = '');
                    setKeypadState(() {});
                  }, isAction: true),
                  _buildNumpadBtn('0', () {
                    _onKeypadPress('0');
                    setKeypadState(() {});
                  }),
                  _buildNumpadBtn('DEL', () {
                    if (_keypadInput.isNotEmpty) {
                      setState(() => _keypadInput = _keypadInput.substring(0, _keypadInput.length - 1));
                      setKeypadState(() {});
                    }
                  }, isAction: true),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumpadBtn(String label, VoidCallback onTap, {bool isAction = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 52,
        decoration: BoxDecoration(
          color: isAction ? const Color(0xFF1B2336) : const Color(0xFF141926),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isAction ? const Color(0xFF9B51E0) : Colors.white,
            fontSize: isAction ? 14 : 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  void _showQueueModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0C101A),
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
                    'Song Queue / Reserved Songs',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
                        child: Text('No songs reserved yet.', style: TextStyle(color: Colors.white54)),
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
                            title: Text(song.title, style: const TextStyle(color: Colors.white)),
                            subtitle: Text("${song.code} • ${song.artist}", style: TextStyle(color: Colors.white.withOpacity(0.6))),
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
