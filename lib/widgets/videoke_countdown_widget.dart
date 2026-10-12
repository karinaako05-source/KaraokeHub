import 'package:flutter/material.dart';

/// Authentic Videoke Intro / Interlude Countdown Widget
/// Renders an arcade-style countdown (4 -> 3 -> 2 -> 1) with glowing beat pulses
/// before the song or next verse begins, warning the singer exactly when to come in.
class VideokeCountdownWidget extends StatelessWidget {
  final int count; // 4, 3, 2, 1
  final String? upcomingLyric;
  final String label;

  const VideokeCountdownWidget({
    super.key,
    required this.count,
    this.upcomingLyric,
    this.label = 'GET READY TO SING',
  });

  @override
  Widget build(BuildContext context) {
    final activeCount = count.clamp(1, 4);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0F172A).withOpacity(0.90),
            const Color(0xFF1E1B4B).withOpacity(0.90),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.25),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Banner Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD700), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mic_rounded, color: Color(0xFFFFD700), size: 14),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4-Beat Countdown Circles / Numbers (4, 3, 2, 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int step = 4; step >= 1; step--) ...[
                _buildBeatCircle(step, step == activeCount, step >= activeCount),
                if (step > 1) const SizedBox(width: 14),
              ],
            ],
          ),

          if (upcomingLyric != null && upcomingLyric!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'FIRST LINE:',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              upcomingLyric!,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBeatCircle(int stepNumber, bool isCurrent, bool isPassedOrCurrent) {
    Color activeColor;
    switch (stepNumber) {
      case 4:
        activeColor = const Color(0xFF00F2FE); // Cyan
        break;
      case 3:
        activeColor = const Color(0xFF00E676); // Green
        break;
      case 2:
        activeColor = const Color(0xFFFFD700); // Yellow
        break;
      case 1:
      default:
        activeColor = const Color(0xFFFF2A6D); // Neon Red/Pink (Final beat!)
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      width: isCurrent ? 52 : 40,
      height: isCurrent ? 52 : 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPassedOrCurrent
            ? activeColor.withOpacity(isCurrent ? 0.35 : 0.15)
            : Colors.white.withOpacity(0.04),
        border: Border.all(
          color: isPassedOrCurrent ? activeColor : Colors.white24,
          width: isCurrent ? 3 : 1.5,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: activeColor.withOpacity(0.6),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '$stepNumber',
        style: TextStyle(
          color: isPassedOrCurrent ? activeColor : Colors.white24,
          fontSize: isCurrent ? 26 : 18,
          fontWeight: FontWeight.w900,
          shadows: isCurrent
              ? [
                  Shadow(color: activeColor, blurRadius: 10),
                  const Shadow(color: Colors.black, blurRadius: 3, offset: Offset(1, 1)),
                ]
              : null,
        ),
      ),
    );
  }
}
