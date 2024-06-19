class Anime {
  final String name;
  final String url;

  Anime({required this.name, required this.url});

  factory Anime.fromJson(Map<String, dynamic> json) {
    return Anime(
      name: json['name'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
    };
  }
}
