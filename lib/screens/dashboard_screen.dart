import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/song_item.dart';
import '../services/song_catalog_service.dart';
import '../services/videoke_flow_manager.dart';
import 'home_screen.dart';
import 'karaoke_player_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SongCatalogService _catalog = SongCatalogService();
  final VideokeFlowManager _flow = VideokeFlowManager();

  String _currentTime = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    _catalog.addListener(_onStateChanged);
    _flow.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _currentTime = DateFormat('EEE, MMM d • hh:mm a').format(DateTime.now());
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _catalog.removeListener(_onStateChanged);
    _flow.removeListener(_onStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveSong = _flow.currentSong != null;

    return Scaffold(
      backgroundColor: const Color(0xFF05070D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top System Bar
              Row(
                children: [
                  _buildCircleBtn(Icons.settings_rounded, 'Settings', () => _showDialog('Settings', 'Audio Output: Native Android Synthesizer\nAES Engine: Hardware Accelerated\nVolume: Balanced')),
                  const SizedBox(width: 10),
                  _buildCircleBtn(Icons.help_outline_rounded, 'Help', () => _showDialog('Help & User Guide', 'Videoke Operating Controls:\n• Keypad: Type 5-digit number and tap ENTER to reserve.\n• Queue: First-In-First-Out reservation queue with Priority Reserve.\n• Player: Authentic Key pitch shift (-12 to +12) and Tempo regulator.')),
                  const SizedBox(width: 10),
                  _buildCircleBtn(Icons.qr_code_2_rounded, 'QR Remote', () => _showDialog('Mobile Remote Pairing', 'Scan QR code to connect mobile phones as wireless songbook remotes.')),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF101624),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Text(
                      _currentTime,
                      style: const TextStyle(
                        color: Color(0xFF00F2FE),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Hero Banner / Live Stage Status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF121A2E), Color(0xFF090E1A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F2FE).withOpacity(0.06),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: hasActiveSong ? const Color(0xFF00F2FE) : const Color(0xFFFFB74D),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                hasActiveSong ? 'STAGE LIVE • PLAYING' : 'STAGE READY • STANDBY',
                                style: TextStyle(
                                  color: hasActiveSong ? const Color(0xFF00F2FE) : const Color(0xFFFFB74D),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            hasActiveSong ? _flow.currentSong!.title : 'KARAOKEHUB NEXT',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasActiveSong
                                ? '${_flow.currentSong!.artist} • Code: ${_flow.currentSong!.code}'
                                : '${_catalog.songs.length} Authenticated songs • ${_flow.queue.length} Reserved in queue',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () {
                        if (hasActiveSong) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => KaraokePlayerScreen(song: _flow.currentSong!),
                            ),
                          );
                        } else if (_catalog.songs.isNotEmpty) {
                          _flow.playSong(_catalog.songs.first);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => KaraokePlayerScreen(song: _catalog.songs.first),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              hasActiveSong ? Icons.mic_external_on_rounded : Icons.play_arrow_rounded,
                              color: Colors.black,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              hasActiveSong ? 'VIEW STAGE' : 'START STAGE',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'MAIN MENU & CONTROLS',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 14),

              // 6 Core Videoke Cards Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.35,
                  children: [
                    // 1. Song Search
                    _buildHubCard(
                      icon: Icons.search_rounded,
                      title: 'SONG SEARCH',
                      subtitle: '${_catalog.songs.length} Songs Loaded',
                      accentColor: const Color(0xFF00F2FE),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      },
                    ),

                    // 2. Karaoke Stage
                    _buildHubCard(
                      icon: Icons.mic_rounded,
                      title: 'KARAOKE STAGE',
                      subtitle: 'Live Prompter & Score Gauge',
                      accentColor: const Color(0xFFFF2A6D),
                      onTap: () {
                        if (hasActiveSong) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => KaraokePlayerScreen(song: _flow.currentSong!),
                            ),
                          );
                        } else if (_catalog.songs.isNotEmpty) {
                          _flow.playSong(_catalog.songs.first);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => KaraokePlayerScreen(song: _catalog.songs.first),
                            ),
                          );
                        } else {
                          _showDialog('Stage Empty', 'Please search and select a song from the songbook first.');
                        }
                      },
                    ),

                    // 3. Queue Drawer
                    _buildHubCard(
                      icon: Icons.queue_music_rounded,
                      title: 'SONG QUEUE',
                      subtitle: '${_flow.queue.length} Reserved Songs',
                      accentColor: const Color(0xFF9B51E0),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      },
                    ),

                    // 4. Rankings / Score Hall of Fame
                    _buildHubCard(
                      icon: Icons.leaderboard_rounded,
                      title: 'RANKINGS',
                      subtitle: 'Hall of Fame Scores',
                      accentColor: const Color(0xFFFFB74D),
                      onTap: () => _showDialog('Top Videoke Rankings', '1. Maria - 100 pts (Ang Huling El Bimbo)\n2. Alex - 99 pts (Bakit Ba Ikaw)\n3. Chris - 98 pts (Jopay)\n4. Sarah - 97 pts (Di Na Muli)'),
                    ),

                    // 5. Artist Directory
                    _buildHubCard(
                      icon: Icons.person_search_rounded,
                      title: 'ARTIST LIST',
                      subtitle: '${_catalog.getArtistSummaries().length} Singers Catalog',
                      accentColor: const Color(0xFF4DD0E1),
                      onTap: () => _showArtistModal(context),
                    ),

                    // 6. Storage & Database Diagnostics
                    _buildHubCard(
                      icon: Icons.storage_rounded,
                      title: 'STORAGE & BLOB',
                      subtitle: 'shubblob AES Active',
                      accentColor: const Color(0xFF81C784),
                      onTap: () => _showDialog(
                        'Storage & Engine Status',
                        'Storage Path: /sdcard/KaraokeHub/\nCatalog: ${_catalog.songs.length} Songs Loaded\nAudio Decryption: Hardware AES-256-CBC\nSound Synth: Android Native SMF MIDI Engine\nBlob Status: shubblob 502 MB Connected',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101624),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white70, size: 20),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }

  Widget _buildHubCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1523),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showArtistModal(BuildContext context) {
    final artists = _catalog.getArtistSummaries();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0E18),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ARTIST CATALOG (${artists.length} SINGERS)',
                  style: const TextStyle(
                    color: Color(0xFF00F2FE),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: artists.length,
                    itemBuilder: (ctx, i) {
                      final a = artists[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF101624),
                          child: Text('${i + 1}', style: const TextStyle(color: Color(0xFF4DD0E1), fontSize: 12)),
                        ),
                        title: Text(a['artist'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        trailing: Text('${a['count']} songs', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                          );
                        },
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
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF101624),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(content, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00F2FE), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
