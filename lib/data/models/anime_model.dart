import '../../domain/entities/anime.dart';

class AnimeModel extends Anime {
  AnimeModel({
    required String id,
    required String title,
    required String url,
    String? thumbnailUrl,
    String? description,
  }) : super(
          id: id,
          title: title,
          url: url,
          thumbnailUrl: thumbnailUrl,
          description: description,
        );

  factory AnimeModel.fromJson(Map<String, dynamic> json) {
    return AnimeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'thumbnail_url': thumbnailUrl,
      'description': description,
    };
  }
}
