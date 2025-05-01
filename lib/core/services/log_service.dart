import 'package:logger/logger.dart';

class LogService {
  static final LogService _instance = LogService._internal();
  late final Logger _logger;

  factory LogService() {
    return _instance;
  }

  LogService._internal() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      level: Level.debug,
    );
  }

  void debug(String message) {
    _logger.d(message);
  }

  void info(String message) {
    _logger.i(message);
  }

  void warning(String message) {
    _logger.w(message);
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.e(
        '$message\nError: $error${stackTrace != null ? '\nStackTrace: $stackTrace' : ''}',
      );
    } else {
      _logger.e(message);
    }
  }

  void verbose(String message) {
    _logger.v(message);
  }

  void wtf(String message) {
    _logger.wtf(message);
  }
}
