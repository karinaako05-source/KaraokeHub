class SongItem {
  final String code;
  final String title;
  final String artist;
  final String genre;
  final String? filePath;
  final int? blobOffset;
  final int? blobLength;
  final String? blobPath;

  const SongItem({
    required this.code,
    required this.title,
    required this.artist,
    required this.genre,
    this.filePath,
    this.blobOffset,
    this.blobLength,
    this.blobPath,
  });

  bool get isBlob => blobOffset != null && blobLength != null;

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'title': title,
      'artist': artist,
      'genre': genre,
      'filePath': filePath,
      'blobOffset': blobOffset,
      'blobLength': blobLength,
      'blobPath': blobPath,
    };
  }

  factory SongItem.fromMap(Map<String, dynamic> map) {
    return SongItem(
      code: map['code'] as String? ?? '00000',
      title: map['title'] as String? ?? 'Unknown Title',
      artist: map['artist'] as String? ?? 'Unknown Artist',
      genre: map['genre'] as String? ?? 'OPM',
      filePath: map['filePath'] as String?,
      blobOffset: map['blobOffset'] as int?,
      blobLength: map['blobLength'] as int?,
      blobPath: map['blobPath'] as String?,
    );
  }
}
