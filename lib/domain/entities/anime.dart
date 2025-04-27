class Anime {
  final String id;
  final String title;
  final String url;
  final String? thumbnailUrl;
  final String? description;

  Anime({
    required this.id,
    required this.title,
    required this.url,
    this.thumbnailUrl,
    this.description,
  });
}
