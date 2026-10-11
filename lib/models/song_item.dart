class SongItem {
  final String code;
  final String title;
  final String artist;
  final String genre;
  final String? filePath;
  final bool isFavorite;

  const SongItem({
    required this.code,
    required this.title,
    required this.artist,
    required this.genre,
    this.filePath,
    this.isFavorite = false,
  });
}
