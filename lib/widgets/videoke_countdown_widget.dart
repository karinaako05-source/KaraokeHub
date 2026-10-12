import 'package:flutter/material.dart';

/// Authentic Videoke Lead-in Countdown Widget (matching Native Android Kotlin)
/// Displays a clean, non-intrusive countdown (4 -> 3 -> 2 -> 1) positioned
/// directly above the upcoming lyric line so lyrics remain 100% visible and unblocked.
class VideokeCountdownWidget extends StatelessWidget {
  final int count; // 4, 3, 2, 1
  final String? upcomingLyric;
  final String label;

  const VideokeCountdownWidget({
    super.key,
    required this.count,
    this.upcomingLyric,
    this.label = 'GET READY',
  });

  @override
  Widget build(BuildContext context) {
    final activeCount = count.clamp(1, 4);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFEB3B).withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFEB3B).withOpacity(0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mic_rounded, color: Color(0xFFFFEB3B), size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFFFEB3B),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 8),
          // Clean 4-3-2-1 Beat dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int step = 4; step >= 1; step--) ...[
                _buildDot(step, step == activeCount, step >= activeCount),
                if (step > 1) const SizedBox(width: 4),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int step, bool isCurrent, bool isPassedOrCurrent) {
    final color = isCurrent
        ? const Color(0xFFFFEB3B)
        : (isPassedOrCurrent ? const Color(0xFF00E676) : Colors.white24);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: isCurrent ? 22 : 16,
      height: isCurrent ? 22 : 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCurrent ? color : color.withOpacity(0.2),
        border: Border.all(color: color, width: isCurrent ? 2 : 1),
      ),
      alignment: Alignment.center,
      child: Text(
        '$step',
        style: TextStyle(
          color: isCurrent ? Colors.black : color,
          fontSize: isCurrent ? 12 : 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// Floating Outlined Countdown Glyph matching CountdownPresentation.kt in Kotlin
class NativeCountdownGlyph extends StatelessWidget {
  final int count;

  const NativeCountdownGlyph({
    super.key,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final number = count.clamp(1, 5);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Thick Black Outline
        Text(
          '$number',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6.0
              ..strokeJoin = StrokeJoin.round
              ..color = Colors.black,
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 10, offset: Offset(2, 3)),
            ],
          ),
        ),
        // Bright Yellow Text matching native countdown.ttf
        Text(
          '$number',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: Color(0xFFFFEB3B),
            shadows: [
              Shadow(color: Color(0xFFFFD600), blurRadius: 12),
            ],
          ),
        ),
      ],
    );
  }
}
