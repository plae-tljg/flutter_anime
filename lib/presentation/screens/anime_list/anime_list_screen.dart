import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/anime_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_view.dart';
import 'anime_list_item.dart';
import '../../../utils/navigation_helper.dart';
import '../../../domain/sources/anime1_me_source.dart';
import '../../../domain/sources/agedm_source.dart';

class AnimeListScreen extends ConsumerWidget {
  const AnimeListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animeListAsync = ref.watch(animeNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Anime List')),
      body: animeListAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, st) => ErrorView(
          error: error.toString(),
          onRetry: () => ref.read(animeNotifierProvider.notifier).loadAnimeList(),
          onGoToSettings: () => _showSourceSelector(context, ref),
        ),
        data: (animes) {
          if (animes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No anime found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showSourceSelector(context, ref),
                    child: const Text('Switch Source'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(animeNotifierProvider.notifier).loadAnimeList(),
            child: ListView.builder(
              itemCount: animes.length,
              itemBuilder: (context, index) {
                final anime = animes[index];
                return AnimeListItem(
                  anime: anime,
                  onTap: () => NavigationHelper.navigateToVideoPlayer(
                    context,
                    anime.url,
                    anime.title,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showSourceSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Anime Source',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.public),
              title: const Text('anime1.me'),
              subtitle: const Text('Classic anime site with video.js player'),
              onTap: () {
                ref.read(animeNotifierProvider.notifier).switchSource(Anime1MeSource());
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.public),
              title: const Text('agedm.com'),
              subtitle: const Text('Direct video element'),
              onTap: () {
                ref.read(animeNotifierProvider.notifier).switchSource(AgedmSource());
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}