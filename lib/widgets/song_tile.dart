import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/song_item.dart';

class SongTile extends StatelessWidget {
  final SongItem song;
  final VoidCallback onPlay;
  final VoidCallback? onReserve;
  final VoidCallback? onQueue;
  final bool isPlaying;

  const SongTile({
    super.key,
    required this.song,
    required this.onPlay,
    this.onReserve,
    this.onQueue,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final handleQueue = onReserve ?? onQueue ?? () {};

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
      decoration: BoxDecoration(
        color: isPlaying ? const Color(0xFF00F2FE).withOpacity(0.08) : const Color(0xFF101624),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlaying ? const Color(0xFF00F2FE).withOpacity(0.4) : Colors.white.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Song Number Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isPlaying
                      ? const Color(0xFF00F2FE).withOpacity(0.2)
                      : const Color(0xFF00F2FE).withOpacity(0.1),
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
              const SizedBox(width: 12),

              // Title and Artist
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isPlaying ? const Color(0xFF00F2FE) : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 12,
                            ),
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
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Reserve button
              IconButton(
                icon: const Icon(Icons.playlist_add_rounded, color: Colors.white70, size: 24),
                tooltip: 'Reserve Song',
                onPressed: handleQueue,
              ),

              // Play button
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.equalizer_rounded : Icons.play_circle_fill_rounded,
                  color: isPlaying ? const Color(0xFFFF2A6D) : const Color(0xFF00F2FE),
                  size: 30,
                ),
                tooltip: isPlaying ? 'Playing' : 'Play Now',
                onPressed: onPlay,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
