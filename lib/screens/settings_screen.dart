import 'dart:io';
import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/audio_engine_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppSettings _settings = AppSettings();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070A13),
      appBar: AppBar(
        title: const Text('SETTINGS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16)),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: _settings,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // 1. SOUNDFONTS
              _buildSectionHeader('SOUNDFONTS (.SF2)'),
              _buildClickItem(
                icon: Icons.piano_rounded,
                title: 'SoundFont SF2',
                subtitle: _settings.selectedSf2Name ?? 'Select SoundFont',
                onTap: _showSoundFontPicker,
              ),

              const SizedBox(height: 16),

              // 2. BACKGROUND VISUAL (BGV)
              _buildSectionHeader('BACKGROUND VISUAL (BGV)'),
              _buildDropdownItem<BackgroundMode>(
                icon: Icons.videocam_rounded,
                title: 'BGV Mode',
                value: _settings.bgvMode,
                items: const [
                  DropdownMenuItem(value: BackgroundMode.video, child: Text('Videos')),
                  DropdownMenuItem(value: BackgroundMode.slideshow, child: Text('Photos Slideshow')),
                  DropdownMenuItem(value: BackgroundMode.none, child: Text('Disabled')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _settings.bgvMode = v);
                    _settings.saveSettings();
                  }
                },
              ),
              if (_settings.bgvMode == BackgroundMode.video)
                _buildSwitchItem(
                  icon: Icons.repeat_rounded,
                  title: 'Continuous Video',
                  subtitle: _settings.bgvContinuousVideo ? 'Continuous video across songs' : 'Cycle clip per song',
                  value: _settings.bgvContinuousVideo,
                  onChanged: (v) {
                    setState(() => _settings.bgvContinuousVideo = v);
                    _settings.saveSettings();
                  },
                ),
              _buildClickItem(
                icon: Icons.folder_rounded,
                title: 'BGV Directory',
                subtitle: _settings.bgvCustomPath ?? '/sdcard/Download/KaraokeHub/content/bgv',
                onTap: () => _showTextInputDialog('BGV Directory', _settings.bgvCustomPath ?? '', (val) {
                  setState(() => _settings.bgvCustomPath = val);
                  _settings.saveSettings();
                }),
              ),

              const SizedBox(height: 16),

              // 3. AUDIO & MIDI ENGINE
              _buildSectionHeader('AUDIO & MIDI ENGINE'),
              _buildSliderItem(
                icon: Icons.volume_up_rounded,
                title: 'MIDI Master Volume',
                value: _settings.midiMasterVolume.toDouble(),
                min: 0,
                max: 200,
                unit: '%',
                onChanged: (v) {
                  setState(() => _settings.midiMasterVolume = v.toInt());
                  _settings.saveSettings();
                },
              ),
              _buildSliderItem(
                icon: Icons.volume_down_rounded,
                title: 'MP3 Master Volume',
                value: _settings.mp3MasterVolume.toDouble(),
                min: 0,
                max: 200,
                unit: '%',
                onChanged: (v) {
                  setState(() => _settings.mp3MasterVolume = v.toInt());
                  _settings.saveSettings();
                },
              ),
              _buildSwitchItem(
                icon: Icons.music_note_rounded,
                title: 'Vocal Mode (Chorus / MP3)',
                subtitle: _settings.vocalChorusMode ? 'Chorus Mode (MP3 + MIDI unison)' : 'Multiplex Mode (MP3 vocals)',
                value: _settings.vocalChorusMode,
                onChanged: (v) {
                  setState(() => _settings.vocalChorusMode = v);
                  _settings.saveSettings();
                },
              ),
              _buildDropdownItem<int>(
                icon: Icons.blur_on_rounded,
                title: 'MIDI Reverb',
                value: _settings.midiReverb,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Off')),
                  DropdownMenuItem(value: 1, child: Text('Low')),
                  DropdownMenuItem(value: 2, child: Text('Medium')),
                  DropdownMenuItem(value: 3, child: Text('High')),
                  DropdownMenuItem(value: 4, child: Text('Default')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _settings.midiReverb = v);
                    _settings.saveSettings();
                  }
                },
              ),
              _buildDropdownItem<int>(
                icon: Icons.waves_rounded,
                title: 'MIDI Chorus',
                value: _settings.midiChorus,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Off')),
                  DropdownMenuItem(value: 1, child: Text('Low')),
                  DropdownMenuItem(value: 2, child: Text('Medium')),
                  DropdownMenuItem(value: 3, child: Text('High')),
                  DropdownMenuItem(value: 4, child: Text('Default')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _settings.midiChorus = v);
                    _settings.saveSettings();
                  }
                },
              ),
              _buildDropdownItem<int>(
                icon: Icons.graphic_eq_rounded,
                title: 'Polyphony (Voices)',
                value: _settings.midiPolyphony,
                items: const [
                  DropdownMenuItem(value: 64, child: Text('64 Voices')),
                  DropdownMenuItem(value: 128, child: Text('128 Voices')),
                  DropdownMenuItem(value: 256, child: Text('256 Voices')),
                  DropdownMenuItem(value: 512, child: Text('512 Voices (Authentic)')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _settings.midiPolyphony = v);
                    _settings.saveSettings();
                  }
                },
              ),

              const SizedBox(height: 16),

              // 4. LYRIC DISPLAY
              _buildSectionHeader('LYRIC PROMPTER'),
              _buildDropdownItem<LyricAlignment>(
                icon: Icons.format_align_center_rounded,
                title: 'Lyric Alignment',
                value: _settings.lyricAlignment,
                items: const [
                  DropdownMenuItem(value: LyricAlignment.center, child: Text('Center')),
                  DropdownMenuItem(value: LyricAlignment.split, child: Text('Left-Right Split')),
                  DropdownMenuItem(value: LyricAlignment.closeSplit, child: Text('Close Split')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _settings.lyricAlignment = v);
                    _settings.saveSettings();
                  }
                },
              ),
              _buildSliderItem(
                icon: Icons.format_size_rounded,
                title: 'Outline Thickness',
                value: _settings.outlineThickness,
                min: 2,
                max: 12,
                unit: 'dp',
                onChanged: (v) {
                  setState(() => _settings.outlineThickness = v);
                  _settings.saveSettings();
                },
              ),
              _buildSwitchItem(
                icon: Icons.color_lens_rounded,
                title: 'Random Lyric Color',
                subtitle: _settings.useRandomLyricColor ? 'Random highlight per song' : 'Standard Cyan Glow',
                value: _settings.useRandomLyricColor,
                onChanged: (v) {
                  setState(() => _settings.useRandomLyricColor = v);
                  _settings.saveSettings();
                },
              ),
              _buildSwitchItem(
                icon: Icons.view_headline_rounded,
                title: '4-Line Display (Portrait)',
                subtitle: _settings.fourLinesPortrait ? 'Show 4 kinetic lines' : 'Standard 3 lines (Intro/Active/Next)',
                value: _settings.fourLinesPortrait,
                onChanged: (v) {
                  setState(() => _settings.fourLinesPortrait = v);
                  _settings.saveSettings();
                },
              ),

              const SizedBox(height: 16),

              // 5. SCORING & FANFARE
              _buildSectionHeader('SCORING & FANFARE'),
              _buildSwitchItem(
                icon: Icons.emoji_events_rounded,
                title: 'Enable Scoring',
                subtitle: _settings.scoreEnabled ? 'Scoring active at song finish' : 'Scoring disabled',
                value: _settings.scoreEnabled,
                onChanged: (v) {
                  setState(() => _settings.scoreEnabled = v);
                  _settings.saveSettings();
                },
              ),
              if (_settings.scoreEnabled) ...[
                _buildDropdownItem<int>(
                  icon: Icons.speed_rounded,
                  title: 'Scoring Difficulty',
                  value: _settings.scoreDifficulty,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Easy / Generous (Low)')),
                    DropdownMenuItem(value: 1, child: Text('Normal (Mid)')),
                    DropdownMenuItem(value: 2, child: Text('Hard / Strict (High)')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _settings.scoreDifficulty = v);
                      _settings.saveSettings();
                    }
                  },
                ),
                _buildDropdownItem<int>(
                  icon: Icons.celebration_rounded,
                  title: 'Fanfare Level',
                  value: _settings.fanfareLevel,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Off (Silent)')),
                    DropdownMenuItem(value: 1, child: Text('Low Fanfare')),
                    DropdownMenuItem(value: 2, child: Text('Medium Fanfare')),
                    DropdownMenuItem(value: 3, child: Text('High Cheers & Applause')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _settings.fanfareLevel = v);
                      _settings.saveSettings();
                    }
                  },
                ),
              ],

              const SizedBox(height: 24),

              // RESET BUTTON
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF5252),
                  side: const BorderSide(color: Color(0xFFFF5252)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  _settings.resetToDefaults();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings reset to authentic defaults')),
                  );
                },
                icon: const Icon(Icons.restore_rounded),
                label: const Text('RESET TO FACTORY DEFAULTS', style: TextStyle(fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF00F2FE),
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildClickItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF131B2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF00F2FE)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      color: const Color(0xFF131B2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        secondary: Icon(icon, color: const Color(0xFF00F2FE)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        value: value,
        activeColor: const Color(0xFF00F2FE),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdownItem<T>({
    required IconData icon,
    required String title,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Card(
      color: const Color(0xFF131B2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00F2FE)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              dropdownColor: const Color(0xFF131B2E),
              underline: const SizedBox(),
              style: const TextStyle(color: Color(0xFF00F2FE), fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderItem({
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      color: const Color(0xFF131B2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF00F2FE), size: 20),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                Text('${value.toInt()}$unit', style: const TextStyle(color: Color(0xFF00F2FE), fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              activeColor: const Color(0xFF00F2FE),
              inactiveColor: Colors.white12,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSoundFontPicker() async {
    final candidateDirs = [
      '/sdcard/SongHub/sound',
      '/storage/emulated/0/SongHub/sound',
      '/sdcard/Download/KaraokeHub/content/sound',
      '/sdcard/Download/karaokehub/content/sound',
      '/storage/emulated/0/Download/KaraokeHub/content/sound',
      '/sdcard/Download',
      '/storage/emulated/0/Download',
      '/sdcard/KaraokeHub',
      '/sdcard/SongHub',
      '/storage/emulated/0/SongHub',
    ];

    final foundItems = <Map<String, dynamic>>[];
    final seenPaths = <String>{};

    // 1. Query native bridge discovery
    try {
      final nativeList = await AudioEngineService().getSoundFonts();
      for (final item in nativeList) {
        final path = item['path'] as String? ?? '';
        if (path.isNotEmpty && !seenPaths.contains(path)) {
          seenPaths.add(path);
          foundItems.add(item);
        }
      }
    } catch (_) {}

    // 2. Scan candidate directories directly via Dart I/O
    for (final d in candidateDirs) {
      try {
        final dir = Directory(d);
        if (dir.existsSync()) {
          for (final f in dir.listSync().whereType<File>()) {
            if (f.path.toLowerCase().endsWith('.sf2')) {
              if (!seenPaths.contains(f.path)) {
                seenPaths.add(f.path);
                foundItems.add({
                  'name': f.uri.pathSegments.last,
                  'path': f.path,
                  'sizeBytes': f.lengthSync(),
                });
              }
            }
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131B2E),
        title: const Text('Select SoundFont (.sf2)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('Automatic (Best Available)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Auto-detects TBOSf, Dream_Sam, or default .sf2', style: TextStyle(color: Colors.white54, fontSize: 11)),
                trailing: _settings.selectedSf2Path == null || _settings.selectedSf2Path!.isEmpty
                    ? const Icon(Icons.check_circle_rounded, color: Color(0xFF00F2FE))
                    : null,
                onTap: () async {
                  setState(() {
                    _settings.selectedSf2Path = null;
                    _settings.selectedSf2Name = 'Automatic (Best Available)';
                  });
                  await _settings.saveSettings();
                  await AudioEngineService().setSoundFont(null);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('SoundFont set to Automatic')),
                    );
                  }
                },
              ),
              const Divider(color: Colors.white24),
              if (foundItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No .sf2 soundfont files found in storage.', style: TextStyle(color: Colors.white70)),
                )
              else
                ...foundItems.map((item) {
                  final name = item['name'] as String? ?? 'SoundFont';
                  final path = item['path'] as String? ?? '';
                  final sizeBytes = item['sizeBytes'] as int? ?? 0;
                  final sizeMb = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
                  final isSelected = _settings.selectedSf2Path == path;

                  return ListTile(
                    title: Text(name, style: TextStyle(color: isSelected ? const Color(0xFF00F2FE) : Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('$sizeMb MB • $path', style: const TextStyle(color: Colors.white54, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF00F2FE)) : null,
                    onTap: () async {
                      setState(() {
                        _settings.selectedSf2Path = path;
                        _settings.selectedSf2Name = name;
                      });
                      await _settings.saveSettings();
                      await AudioEngineService().setSoundFont(path);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Active SoundFont: $name')),
                        );
                      }
                    },
                  );
                }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE', style: TextStyle(color: Color(0xFF00F2FE))),
          ),
        ],
      ),
    );
  }

  void _showTextInputDialog(String title, String initialValue, ValueChanged<String> onSaved) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131B2E),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter path',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00F2FE))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00F2FE), foregroundColor: Colors.black),
            onPressed: () {
              onSaved(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
