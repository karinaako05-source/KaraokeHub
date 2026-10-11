class SongItem {
  final String code;
  final String title;
  final String artist;
  final String genre;
  final bool isFavorite;

  const SongItem({
    required this.code,
    required this.title,
    required this.artist,
    required this.genre,
    this.isFavorite = false,
  });
}
