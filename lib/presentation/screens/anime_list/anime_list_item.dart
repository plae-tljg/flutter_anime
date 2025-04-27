import 'package:flutter/material.dart';
import '../../../domain/entities/anime.dart';

class AnimeListItem extends StatelessWidget {
  final Anime anime;
  final VoidCallback onTap;

  const AnimeListItem({
    Key? key,
    required this.anime,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: anime.thumbnailUrl != null
            ? Image.network(
                anime.thumbnailUrl!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.movie);
                },
              )
            : const Icon(Icons.movie),
        title: Text(anime.title),
        subtitle: anime.description != null
            ? Text(
                anime.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
