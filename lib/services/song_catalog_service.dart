import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../models/song_item.dart';

class SongCatalogService extends ChangeNotifier {
  static final SongCatalogService _instance = SongCatalogService._internal();
  factory SongCatalogService() => _instance;
  SongCatalogService._internal() {
    unawaited(reloadCatalog());
  }

  final List<SongItem> _songs = [];
  List<SongItem> get songs => List.unmodifiable(_songs);

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  int _nextGeneratedCode = 50001;
  Future<void>? _catalogLoad;
  Future<void>? _storageScan;

  Future<void> reloadCatalog() {
    return _catalogLoad ??= _loadCatalog().whenComplete(() {
      _catalogLoad = null;
      notifyListeners();
    });
  }

  Future<void> _loadCatalog() async {
    if (_storageScan != null) await _storageScan;
    _songs.clear();
    _nextGeneratedCode = 50001;
    activeBlobPath = null;
    // Load only songs present on the device.
    await _tryLoadShubCatalog();
    await _scanDeviceStorage();
  }

  static String? activeBlobPath;

  Future<void> _tryLoadShubCatalog() async {
    final candidateIdxPaths = [
      '/sdcard/SongHub/idx/shubidx',
      '/storage/emulated/0/SongHub/idx/shubidx',
      '/sdcard/SongHub/content/idx/shubidx',
      '/sdcard/Download/KaraokeHub/content/idx/shubidx',
      '/sdcard/Download/karaokehub/content/idx/shubidx',
      '/storage/emulated/0/Download/KaraokeHub/content/idx/shubidx',
      '/storage/emulated/0/Download/karaokehub/content/idx/shubidx',
      '/sdcard/Download/idx/shubidx',
      '/sdcard/Download/shubidx',
      '/storage/emulated/0/Download/idx/shubidx',
      '/storage/emulated/0/Download/shubidx',
      '/sdcard/KaraokeHub/karaokehub-private-020/content/idx/shubidx',
      '/sdcard/KaraokeHub/idx/shubidx',
      '/sdcard/Download/KaraokeHub/idx/shubidx',
      '/storage/emulated/0/KaraokeHub/karaokehub-private-020/content/idx/shubidx',
      '/storage/emulated/0/KaraokeHub/idx/shubidx',
    ];

    File? foundIdxFile;
    for (final path in candidateIdxPaths) {
      try {
        final file = File(path);
        if (file.existsSync() && file.lengthSync() > 0) {
          foundIdxFile = file;
          break;
        }
      } catch (_) {}
    }

    // Fallback: search inside /sdcard/Download/ and /sdcard/SongHub/ for any idx folder or shubidx
    if (foundIdxFile == null) {
      final searchDirs = [
        Directory('/sdcard/SongHub'),
        Directory('/storage/emulated/0/SongHub'),
        Directory('/sdcard/Download'),
        Directory('/storage/emulated/0/Download'),
      ];
      for (final searchDir in searchDirs) {
        try {
          if (searchDir.existsSync()) {
            for (final entity in searchDir.listSync(recursive: false)) {
              if (entity is Directory &&
                  entity.path.toLowerCase().endsWith('idx')) {
                final nested = File('${entity.path}/shubidx');
                if (nested.existsSync() && nested.lengthSync() > 0) {
                  foundIdxFile = nested;
                  break;
                }
              }
            }
          }
        } catch (_) {}
        if (foundIdxFile != null) break;
      }
    }

    if (foundIdxFile != null) {
      // Resolve matching shubblob path
      final candidateBlobPaths = [
        '${foundIdxFile.parent.path}/shubblob',
        '/sdcard/SongHub/idx/shubblob',
        '/storage/emulated/0/SongHub/idx/shubblob',
        '/sdcard/Download/idx/shubblob',
        '/sdcard/Download/shubblob',
        '/storage/emulated/0/Download/idx/shubblob',
        '/sdcard/KaraokeHub/karaokehub-private-020/content/idx/shubblob',
        '/sdcard/KaraokeHub/idx/shubblob',
      ];
      for (final blobPath in candidateBlobPaths) {
        final bf = File(blobPath);
        if (bf.existsSync() && bf.lengthSync() > 0) {
          activeBlobPath = blobPath;
          break;
        }
      }

      try {
        final bytes = await foundIdxFile.readAsBytes();
        _parseShubIdx(bytes, activeBlobPath);
      } catch (_) {}
    }
  }

  void _parseShubIdx(Uint8List bytes, [String? blobPath]) {
    if (bytes.length < 56) return;
    final byteData = ByteData.sublistView(bytes);
    final start = byteData.getUint32(52, Endian.little);
    if (start <= 0 || start >= bytes.length) return;

    final singers = <String>[];
    final codes = <int>[];
    final genres = <int, String>{};
    final parsedSongs = <Map<String, dynamic>>[];

    int offset = start;
    const typeSong = 1;
    const typeGenre = 4;
    const typeSinger = 5;
    const typeCode = 9;

    while (offset < bytes.length) {
      final rtype = bytes[offset];
      if (rtype == 0) {
        offset++;
        continue;
      }
      if (rtype == typeCode) {
        if (offset + 4 <= bytes.length) {
          final raw = typeCode |
              (bytes[offset + 1] << 8) |
              (bytes[offset + 2] << 16) |
              (bytes[offset + 3] << 24);
          final code = (((raw >> 16) & 0xffff) | ((raw & 0xff00) << 8));
          codes.add(code);
          offset += 4;
          continue;
        }
        break;
      }
      if (offset + 2 > bytes.length) break;
      final length = bytes[offset + 1];
      if (length < 2 || offset + length > bytes.length) break;

      if (rtype == typeGenre) {
        final gid = bytes[offset + 2];
        try {
          final gname =
              latin1.decode(bytes.sublist(offset + 5, offset + length)).trim();
          genres[gid] = gname;
        } catch (_) {}
      } else if (rtype == typeSinger) {
        try {
          final sname =
              latin1.decode(bytes.sublist(offset + 5, offset + length)).trim();
          singers.add(sname);
        } catch (_) {
          singers.add('Unknown');
        }
      } else if (rtype == typeSong) {
        final genreId = bytes[offset + 2];
        final flags = bytes[offset + 3];
        final mode = (flags & 0x80 != 0) ? 2 : 1;
        final rawSinger = byteData.getUint16(offset + 4, Endian.little);
        final singerIdx = rawSinger & 0x3fff;
        final musicLen = byteData.getUint16(offset + 6, Endian.little);
        final musicOff = byteData.getInt32(offset + 8, Endian.little);
        final cursor = (mode == 2) ? offset + 18 : offset + 12;
        final fixedPayload = (mode == 2) ? 16 : 10;
        final titleLen = (length - 2) - fixedPayload;

        String title = 'Unknown Title';
        if (titleLen > 0 && cursor + titleLen <= bytes.length) {
          try {
            title =
                latin1.decode(bytes.sublist(cursor, cursor + titleLen)).trim();
          } catch (_) {}
        }
        parsedSongs.add({
          'genreId': genreId,
          'singerIdx': singerIdx,
          'musicOff': musicOff,
          'musicLen': musicLen,
          'title': title,
        });
      }

      offset += length;
    }

    // Map parsed songs into SongItem models
    for (int i = 0; i < parsedSongs.length; i++) {
      final item = parsedSongs[i];
      final codeInt = (i < codes.length) ? codes[i] : i;
      final codeStr = codeInt.toString().padLeft(5, '0');
      final singerIdx = item['singerIdx'] as int;
      final artist =
          (singerIdx < singers.length) ? singers[singerIdx] : 'Unknown';
      final genreId = item['genreId'] as int;
      final genre = genres[genreId] ?? 'OPM';

      _songs.add(
        SongItem(
          code: codeStr,
          title: item['title'] as String,
          artist: artist,
          genre: genre,
          blobOffset: item['musicOff'] as int,
          blobLength: item['musicLen'] as int,
          blobPath: blobPath,
        ),
      );
    }
  }

  Future<void> scanDeviceStorage([List<String>? customFolders]) async {
    if (_catalogLoad != null) await _catalogLoad;
    await (_storageScan ??= _scanDeviceStorage(customFolders).whenComplete(() {
      _storageScan = null;
    }));
  }

  Future<void> _scanDeviceStorage([List<String>? customFolders]) async {
    _isScanning = true;
    notifyListeners();

    final searchDirs = customFolders ??
        [
          '/sdcard/Download',
          '/sdcard/Music',
          '/sdcard/KaraokeHub/songs',
          '/sdcard/SongHub/songs',
        ];

    final Set<String> existingPaths =
        _songs.map((s) => s.filePath ?? '').toSet();

    for (final dirPath in searchDirs) {
      try {
        final dir = Directory(dirPath);
        if (dir.existsSync()) {
          final entities = dir.listSync(recursive: false);
          for (final entity in entities) {
            if (entity is File) {
              final path = entity.path;
              final lower = path.toLowerCase();
              if (lower.endsWith('.mp3') ||
                  lower.endsWith('.mid') ||
                  lower.endsWith('.kar') ||
                  lower.endsWith('.wav') ||
                  lower.endsWith('.m4a') ||
                  lower.endsWith('.mp4')) {
                if (!existingPaths.contains(path)) {
                  _parseAndAddFile(entity);
                  existingPaths.add(path);
                }
              }
            }
          }
        }
      } catch (_) {}
    }

    _isScanning = false;
    notifyListeners();
  }

  void _parseAndAddFile(File file) {
    final fileName = file.uri.pathSegments.last;
    final dotIndex = fileName.lastIndexOf('.');
    final baseName =
        dotIndex != -1 ? fileName.substring(0, dotIndex) : fileName;
    final extension = dotIndex != -1
        ? fileName.substring(dotIndex + 1).toUpperCase()
        : 'AUDIO';

    String code = '$_nextGeneratedCode';
    _nextGeneratedCode++;

    String title = baseName;
    String artist = 'Local Artist';

    final matchCode = RegExp(r'^(\d{3,6})\s*[-_]\s*(.+)').firstMatch(baseName);
    if (matchCode != null) {
      code = matchCode.group(1)!;
      final rest = matchCode.group(2)!;
      final parts = rest.split(RegExp(r'\s*[-_]\s*'));
      if (parts.length >= 2) {
        title = parts[0].trim();
        artist = parts.sublist(1).join(' - ').trim();
      } else {
        title = rest.trim();
      }
    } else {
      final parts = baseName.split(RegExp(r'\s*[-_]\s*'));
      if (parts.length >= 2) {
        artist = parts[0].trim();
        title = parts.sublist(1).join(' - ').trim();
      }
    }

    _songs.add(
      SongItem(
        code: code,
        title: title,
        artist: artist,
        genre: extension,
        filePath: file.path,
      ),
    );
  }

  SongItem? findByCode(String code) {
    try {
      final clean = code.trim();
      return _songs.firstWhere((s) {
        if (s.code == clean) return true;
        final cInt = int.tryParse(s.code);
        final qInt = int.tryParse(clean);
        return cInt != null && qInt != null && cInt == qInt;
      });
    } catch (_) {
      return null;
    }
  }

  List<SongItem> search(String query, {String? genre}) {
    final q = query.trim().toLowerCase();
    return _songs.where((song) {
      final matchesGenre = genre == null ||
          genre == 'ALL' ||
          song.genre.toUpperCase() == genre.toUpperCase();
      if (!matchesGenre) return false;
      if (q.isEmpty) return true;
      return song.code.toLowerCase().contains(q) ||
          song.title.toLowerCase().contains(q) ||
          song.artist.toLowerCase().contains(q);
    }).toList();
  }

  List<String> getGenres() {
    final genres = {'ALL'};
    for (final song in _songs) {
      if (song.genre.isNotEmpty) {
        genres.add(song.genre.toUpperCase());
      }
    }
    return genres.toList();
  }

  List<Map<String, dynamic>> getArtistSummaries() {
    final Map<String, int> counts = {};
    for (final song in _songs) {
      final a = song.artist.trim();
      if (a.isNotEmpty) {
        counts[a] = (counts[a] ?? 0) + 1;
      }
    }
    final list =
        counts.entries.map((e) => {'artist': e.key, 'count': e.value}).toList();
    list.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return list;
  }
}
