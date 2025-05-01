import 'package:logger/logger.dart';
import 'dart:collection';

class LogService {
  static final LogService _instance = LogService._internal();
  late final Logger _logger;
  final List<String> _logHistory = [];
  final int _maxLogHistory = 1000; // 最多保存1000条日志

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

  void _addToHistory(String message) {
    _logHistory.add('${DateTime.now()} - $message');
    if (_logHistory.length > _maxLogHistory) {
      _logHistory.removeAt(0);
    }
  }

  List<String> getLogHistory() {
    return List.unmodifiable(_logHistory);
  }

  void clearLogs() {
    _logHistory.clear();
  }

  void debug(String message) {
    _logger.d(message);
    _addToHistory('DEBUG: $message');
  }

  void info(String message) {
    _logger.i(message);
    _addToHistory('INFO: $message');
  }

  void warning(String message) {
    _logger.w(message);
    _addToHistory('WARNING: $message');
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      final errorMessage =
          '$message\nError: $error${stackTrace != null ? '\nStackTrace: $stackTrace' : ''}';
      _logger.e(errorMessage);
      _addToHistory('ERROR: $errorMessage');
    } else {
      _logger.e(message);
      _addToHistory('ERROR: $message');
    }
  }

  void verbose(String message) {
    _logger.v(message);
    _addToHistory('VERBOSE: $message');
  }

  void wtf(String message) {
    _logger.wtf(message);
    _addToHistory('WTF: $message');
  }
}
