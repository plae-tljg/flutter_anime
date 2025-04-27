import 'package:flutter/material.dart';
import '../../../utils/navigation_helper.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('动漫应用'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => NavigationHelper.navigateToAnimeList(context),
              child: const Text('浏览动漫列表'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: 实现视频库功能
              },
              child: const Text('我的视频库'),
            ),
          ],
        ),
      ),
    );
  }
}
