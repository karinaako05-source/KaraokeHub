import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/song_item.dart';
import 'home_screen.dart';
import 'karaoke_player_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _currentTime = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildCircleBtn(Icons.settings_rounded, 'Settings', () => _showDialog('Settings', 'Configure audio output and soundfonts.')),
                  const SizedBox(width: 10),
                  _buildCircleBtn(Icons.help_outline_rounded, 'Help', () => _showDialog('Help & User Guide', 'Videoke Operating Controls:\n• Song Search: Type 5-digit number or title.\n• Queue: Reserve songs.\n• Player: Pitch and tempo controls.')),
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

              // Brand Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.mic_external_on_rounded, color: Colors.black, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KARAOKEHUB',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      Text(
                        'NEXT-GEN PRO VIDEOKE DASHBOARD',
                        style: TextStyle(
                          color: Color(0xFF00F2FE),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // The 6 Hub Action Cards
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.15,
                  children: [
                    // 1. Song Search
                    _buildHubCard(
                      icon: Icons.search_rounded,
                      title: 'SONG SEARCH',
                      subtitle: 'Catalog & 5-Digit Keypad',
                      accentColor: const Color(0xFF00F2FE),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      },
                    ),

                    // 2. Karaoke Stage
                    _buildHubCard(
                      icon: Icons.play_circle_fill_rounded,
                      title: 'KARAOKE STAGE',
                      subtitle: 'Full Lyrics & Prompter',
                      accentColor: const Color(0xFFE040FB),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const KaraokePlayerScreen(
                              song: SongItem(
                                code: '71001',
                                title: 'Ang Huling El Bimbo',
                                artist: 'Eraserheads',
                                genre: 'OPM',
                              ),
                              queue: [],
                            ),
                          ),
                        );
                      },
                    ),

                    // 3. Reserved Queue
                    _buildHubCard(
                      icon: Icons.queue_music_rounded,
                      title: 'SONG QUEUE',
                      subtitle: 'Reserved Song Playlist',
                      accentColor: const Color(0xFF9B51E0),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      },
                    ),

                    // 4. Rankings
                    _buildHubCard(
                      icon: Icons.leaderboard_rounded,
                      title: 'RANKINGS',
                      subtitle: 'Top Scores & Hall of Fame',
                      accentColor: const Color(0xFFFFB74D),
                      onTap: () => _showDialog('Top Rankings', '1. Alex - 99 pts (Bakit Ba Ikaw)\n2. Chris - 98 pts (214)\n3. Maria - 97 pts (Torete)'),
                    ),

                    // 5. Artist Search
                    _buildHubCard(
                      icon: Icons.person_search_rounded,
                      title: 'ARTIST LIST',
                      subtitle: 'Browse by Singers & Bands',
                      accentColor: const Color(0xFF4DD0E1),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      },
                    ),

                    // 6. Storage Diagnostics
                    _buildHubCard(
                      icon: Icons.storage_rounded,
                      title: 'STORAGE',
                      subtitle: 'Soundfonts & SD Scanner',
                      accentColor: const Color(0xFF81C784),
                      onTap: () => _showDialog('Storage Diagnostics', 'Storage Path: /sdcard/Download\nDatabase: SQLite Active\nSoundFont: BASSMIDI Loaded'),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1523).withOpacity(0.9),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accentColor.withOpacity(0.2), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accentColor, size: 26),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF101624),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(color: Colors.white70, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00F2FE), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
