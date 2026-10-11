import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/song_item.dart';

class SongTile extends StatelessWidget {
  final SongItem song;
  final VoidCallback onPlay;
  final VoidCallback onQueue;

  const SongTile({
    super.key,
    required this.song,
    required this.onPlay,
    required this.onQueue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF131722).withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Song Number Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F2FE).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF00F2FE).withOpacity(0.35),
                    ),
                  ),
                  child: Text(
                    song.code,
                    style: const TextStyle(
                      color: Color(0xFF00F2FE),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Title and Artist
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9B51E0).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              song.genre,
                              style: const TextStyle(
                                color: Color(0xFFC084FC),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                IconButton(
                  icon: const Icon(Icons.playlist_add_rounded, color: Colors.white70),
                  tooltip: 'Reserve to Queue',
                  onPressed: onQueue,
                ),
                IconButton(
                  icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF00F2FE), size: 32),
                  tooltip: 'Play Now',
                  onPressed: onPlay,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
