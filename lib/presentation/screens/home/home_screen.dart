import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/navigation_helper.dart';
import '../settings/settings_screen.dart';
import '../video_library/video_library_screen.dart';
import '../downloads/downloads_screen.dart';
import '../../providers/anime_provider.dart';
import '../../../domain/services/download_manager.dart';
import '../../../domain/entities/download_item.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _HomeContent(),
    const VideoLibraryScreen(),
    const DownloadsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(animeNotifierProvider.notifier).loadAnimeList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anime Webview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(animeNotifierProvider.notifier).loadAnimeList();
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: _buildDownloadBadge(),
            label: 'Downloads',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildDownloadBadge() {
    return StreamBuilder<Map<String, DownloadItem>>(
      stream: DownloadManager().downloadsStream,
      builder: (context, snapshot) {
        final activeCount = snapshot.data?.values
                .where((d) => d.status == DownloadStatus.downloading)
                .length ?? 0;

        return Badge(
          isLabelVisible: activeCount > 0,
          label: Text(activeCount.toString()),
          child: const Icon(Icons.download),
        );
      },
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSource = ref.watch(currentSourceProvider);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Current Source: ${currentSource.name}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => NavigationHelper.navigateToAnimeList(context),
            icon: const Icon(Icons.list),
            label: const Text('Browse Anime List'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              ref.read(animeNotifierProvider.notifier).loadAnimeList();
              NavigationHelper.navigateToAnimeList(context);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reload & Browse'),
          ),
        ],
      ),
    );
  }
}