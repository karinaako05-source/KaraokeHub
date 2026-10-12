import 'package:flutter/material.dart';

/// Authentic Dual-Line Videoke Lyric Widget matching KaraokeLyricView.kt
/// Supports sub-syllable smooth left-to-right highlight sweeping with
/// heavy rounded black outlines and crisp contrast on video backgrounds.
class VideokeLyricWidget extends StatelessWidget {
  final Map<String, dynamic> lyricLine;
  final int positionMs;
  final Color highlightColor;
  final Color baseColor;
  final double fontSize;
  final double outlineWidth;
  final Alignment alignment;
  final TextAlign textAlign;

  const VideokeLyricWidget({
    super.key,
    required this.lyricLine,
    required this.positionMs,
    this.highlightColor = const Color(0xFFFFD600), // Classic KTV Gold
    this.baseColor = Colors.white,
    this.fontSize = 24.0,
    this.outlineWidth = 4.5,
    this.alignment = Alignment.center,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final fullText = lyricLine['text'] as String? ?? '';
    final tokensRaw = lyricLine['tokens'] as List?;
    final lineStartMs = lyricLine['timeMs'] as int? ?? 0;
    final lineEndMs = lyricLine['endMs'] as int? ?? (lineStartMs + 3000);

    // Calculate progress fraction (0.0 to 1.0)
    double progress = 0.0;
    if (positionMs <= lineStartMs) {
      progress = 0.0;
    } else if (positionMs >= lineEndMs) {
      progress = 1.0;
    } else if (tokensRaw != null && tokensRaw.isNotEmpty) {
      // Calculate syllable-by-syllable weighted progress based on character count and token timings
      final tokens = tokensRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      double totalChars = 0;
      for (final t in tokens) {
        totalChars += (t['text'] as String? ?? '').length;
      }
      if (totalChars <= 0) totalChars = fullText.length.toDouble();

      double charsPassed = 0;
      for (final t in tokens) {
        final tText = t['text'] as String? ?? '';
        final tStart = t['startMs'] as int? ?? lineStartMs;
        final tEnd = t['endMs'] as int? ?? (tStart + 500);
        final tLen = tText.length.toDouble();

        if (positionMs >= tEnd) {
          charsPassed += tLen;
        } else if (positionMs > tStart) {
          final frac = (positionMs - tStart) / (tEnd - tStart).clamp(1, 999999);
          charsPassed += tLen * frac.clamp(0.0, 1.0);
          break;
        } else {
          break;
        }
      }
      progress = (charsPassed / (totalChars > 0 ? totalChars : 1.0)).clamp(0.0, 1.0);
    } else {
      // Fallback linear interpolation over line duration
      progress = ((positionMs - lineStartMs) / (lineEndMs - lineStartMs).clamp(1, 999999)).clamp(0.0, 1.0);
    }

    return Align(
      alignment: alignment,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Stack(
          alignment: alignment,
          children: [
            // 1. BASE INACTIVE LAYER (White text with black outline)
            Stack(
              children: [
                // Black outline
                Text(
                  fullText,
                  textAlign: textAlign,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = outlineWidth
                      ..strokeJoin = StrokeJoin.round
                      ..color = Colors.black,
                    shadows: const [
                      Shadow(color: Colors.black, blurRadius: 6, offset: Offset(2, 2)),
                    ],
                  ),
                ),
                // White fill
                Text(
                  fullText,
                  textAlign: textAlign,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: baseColor,
                  ),
                ),
              ],
            ),

            // 2. ACTIVE HIGHLIGHT LAYER (Clipped precisely from left to right as sound progresses)
            if (progress > 0.0)
              ClipRect(
                clipper: _LeftToRightClipper(progress),
                child: Stack(
                  children: [
                    // Highlight outline
                    Text(
                      fullText,
                      textAlign: textAlign,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = outlineWidth
                          ..strokeJoin = StrokeJoin.round
                          ..color = Colors.black,
                      ),
                    ),
                    // Glowing Highlight fill (Warm Gold / Cyan neon videoke color)
                    Text(
                      fullText,
                      textAlign: textAlign,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: highlightColor,
                        shadows: [
                          Shadow(color: highlightColor.withOpacity(0.9), blurRadius: 10),
                          const Shadow(color: Colors.white, blurRadius: 2),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LeftToRightClipper extends CustomClipper<Rect> {
  final double progress;
  _LeftToRightClipper(this.progress);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * progress, size.height);
  }

  @override
  bool shouldReclip(_LeftToRightClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}
