class AppConfig {
  static const String baseUrl = 'https://anime1.me/';
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  // 视频相关配置
  static const String videoStoragePath = 'videos';
  static const List<String> supportedVideoFormats = ['.mp4', '.webm'];

  // WebView配置
  static const int webViewLoadDelay = 3; // 秒
}
