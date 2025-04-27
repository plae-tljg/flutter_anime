import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/di/service_locator.dart';
import '../../providers/anime_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_view.dart';
import 'anime_list_item.dart';
import '../../../utils/navigation_helper.dart';

class AnimeListScreen extends StatefulWidget {
  const AnimeListScreen({Key? key}) : super(key: key);

  @override
  State<AnimeListScreen> createState() => _AnimeListScreenState();
}

class _AnimeListScreenState extends State<AnimeListScreen> {
  late final AnimeProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = getIt<AnimeProvider>();
    _loadData();
  }

  Future<void> _loadData() async {
    await _provider.loadAnimeList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('动漫列表'),
      ),
      body: ChangeNotifierProvider.value(
        value: _provider,
        child: Consumer<AnimeProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const LoadingIndicator();
            }

            if (provider.error != null) {
              return ErrorView(
                error: provider.error!,
                onRetry: _loadData,
              );
            }

            if (provider.animes.isEmpty) {
              return const Center(
                child: Text('暂无动漫'),
              );
            }

            return RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                itemCount: provider.animes.length,
                itemBuilder: (context, index) {
                  final anime = provider.animes[index];
                  return AnimeListItem(
                    anime: anime,
                    onTap: () async {
                      try {
                        final videoUrl = await provider.getVideoUrl(anime.url);
                        if (!mounted) return;
                        NavigationHelper.navigateToVideoPlayer(
                          context,
                          videoUrl,
                          anime.title,
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('获取视频失败: $e')),
                        );
                      }
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
