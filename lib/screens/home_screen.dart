import 'package:flutter/material.dart';
import '../models/song_item.dart';
import '../services/audio_engine_service.dart';
import '../services/song_catalog_service.dart';
import '../services/videoke_flow_manager.dart';
import '../widgets/song_tile.dart';
import 'karaoke_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final SongCatalogService _catalog = SongCatalogService();
  final VideokeFlowManager _flow = VideokeFlowManager();
  final AudioEngineService _audio = AudioEngineService();

  String _selectedGenre = 'ALL';
  String _keypadInput = '';

  @override
  void initState() {
    super.initState();
    _catalog.addListener(_onStateChanged);
    _flow.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _catalog.removeListener(_onStateChanged);
    _flow.removeListener(_onStateChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filteredSongs = _catalog.search(_searchCtrl.text, genre: _selectedGenre);
    final genres = _catalog.getGenres();

    return Scaffold(
      backgroundColor: const Color(0xFF06080E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C101B),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SONGBOOK & SEARCH',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              '${_catalog.songs.length} Authenticated Videoke Songs',
              style: const TextStyle(color: Color(0xFF00F2FE), fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Rescan Storage',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scanning storage for karaoke songs & blobs...')),
              );
              await _catalog.scanDeviceStorage();
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.queue_music_rounded, color: Colors.white),
                onPressed: () => _showQueueDrawer(context),
              ),
              if (_flow.queue.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF2A6D),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_flow.queue.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Keypad triggers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF101624),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Search title, artist, or 5-digit code...',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF00F2FE), size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () => _showKeypadModal(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.dialpad_rounded, color: Colors.black, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'KEYPAD',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Genre chips
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: genres.length,
              itemBuilder: (ctx, i) {
                final genre = genres[i];
                final isSelected = genre == _selectedGenre;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(genre),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedGenre = genre);
                    },
                    selectedColor: const Color(0xFF9B51E0),
                    backgroundColor: const Color(0xFF101624),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF9B51E0) : Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Song List
          Expanded(
            child: filteredSongs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.music_off_rounded, size: 48, color: Colors.white.withOpacity(0.2)),
                        const SizedBox(height: 12),
                        const Text(
                          'No songs found matching query.',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredSongs.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemBuilder: (ctx, idx) {
                      final song = filteredSongs[idx];
                      final isCurrent = _flow.currentSong?.code == song.code;
                      return SongTile(
                        song: song,
                        isPlaying: isCurrent && _flow.isPlaying,
                        onPlay: () {
                          _flow.playSong(song);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => KaraokePlayerScreen(song: song),
                            ),
                          );
                        },
                        onReserve: () {
                          final wasIdle = _flow.currentSong == null;
                          _flow.reserve(song);
                          if (wasIdle) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => KaraokePlayerScreen(song: song),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Reserved: ${song.title} (${song.code})'),
                                duration: const Duration(seconds: 2),
                                action: SnackBarAction(
                                  label: 'PRIORITY',
                                  textColor: const Color(0xFFFF2A6D),
                                  onPressed: () => _flow.reserve(song, priority: true),
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),

          // Mini Player Dock if song is active
          if (_flow.currentSong != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1523),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F2FE).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.mic_external_on_rounded, color: Color(0xFF00F2FE), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _flow.currentSong!.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${_flow.currentSong!.artist} • ${_flow.currentSong!.code}',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _flow.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                      color: const Color(0xFF00F2FE),
                      size: 32,
                    ),
                    onPressed: () => _flow.togglePlayPause(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, color: Colors.white70, size: 28),
                    tooltip: 'Next Reserved Song',
                    onPressed: () => _flow.next(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.fullscreen_rounded, color: Colors.white70, size: 24),
                    tooltip: 'Open Stage',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => KaraokePlayerScreen(song: _flow.currentSong!),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showQueueDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0C101B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final q = _flow.queue;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RESERVED QUEUE (${q.length})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (q.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              _flow.clearQueue();
                              setModalState(() {});
                            },
                            child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
                          ),
                      ],
                    ),
                    const Divider(color: Colors.white12),
                    Expanded(
                      child: q.isEmpty
                          ? const Center(
                              child: Text(
                                'No songs reserved yet.\nSearch songs or use Keypad to reserve.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white38),
                              ),
                            )
                          : ListView.builder(
                              itemCount: q.length,
                              itemBuilder: (ctx, i) {
                                final item = q[i];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF101624),
                                    child: Text('${i + 1}', style: const TextStyle(color: Color(0xFF00F2FE))),
                                  ),
                                  title: Text(item.title, style: const TextStyle(color: Colors.white)),
                                  subtitle: Text('${item.artist} • ${item.code}', style: const TextStyle(color: Colors.white54)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close_rounded, color: Colors.white38),
                                    onPressed: () {
                                      _flow.removeFromQueue(item.code);
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
            );
          },
        );
      },
    );
  }

  void _showKeypadModal(BuildContext context) {
    _keypadInput = '';
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0E18),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '5-DIGIT VIDEOKE KEYPAD',
                      style: TextStyle(
                        color: Color(0xFF00F2FE),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Display Screen for Code
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF04060A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00F2FE).withOpacity(0.3)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _keypadInput.isEmpty ? '_ _ _ _ _' : _keypadInput.padRight(5, '_'),
                        style: const TextStyle(
                          color: Color(0xFF00F2FE),
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Keypad grid
                    Column(
                      children: [
                        _buildKeyRow(['1', '2', '3'], setModalState),
                        const SizedBox(height: 10),
                        _buildKeyRow(['4', '5', '6'], setModalState),
                        const SizedBox(height: 10),
                        _buildKeyRow(['7', '8', '9'], setModalState),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildKeypadBtn('CLEAR', Colors.redAccent.withOpacity(0.2), Colors.redAccent, () {
                              setModalState(() => _keypadInput = '');
                            }),
                            const SizedBox(width: 10),
                            _buildKeypadBtn('0', const Color(0xFF131A2B), Colors.white, () {
                              if (_keypadInput.length < 5) {
                                _audio.playSfx('num_0');
                                setModalState(() => _keypadInput += '0');
                              }
                            }),
                            const SizedBox(width: 10),
                            _buildKeypadBtn('ENTER', const Color(0xFF00F2FE), Colors.black, () {
                              _handleKeypadEnter(context);
                            }),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildKeyRow(List<String> keys, void Function(void Function()) setModalState) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildKeypadBtn(key, const Color(0xFF131A2B), Colors.white, () {
              if (_keypadInput.length < 5) {
                _audio.playSfx('num_$key');
                setModalState(() => _keypadInput += key);
              }
            }),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadBtn(String label, Color bg, Color textColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _handleKeypadEnter(BuildContext context) {
    if (_keypadInput.isEmpty) return;
    final found = _catalog.findByCode(_keypadInput);
    Navigator.of(context).pop();

    if (found != null) {
      final wasIdle = _flow.currentSong == null;
      _flow.reserve(found);
      if (wasIdle) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => KaraokePlayerScreen(song: found)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Reserved: [${found.code}] ${found.title} - ${found.artist}'),
            backgroundColor: const Color(0xFF003847),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'PLAY NOW',
              textColor: const Color(0xFF00F2FE),
              onPressed: () {
                _flow.playSong(found);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => KaraokePlayerScreen(song: found)),
                );
              },
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Song code $_keypadInput not found in catalog.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
