import 'package:flutter/foundation.dart';

class ErrorHandler {
  static void handleError(dynamic error, StackTrace stackTrace) {
    if (kDebugMode) {
      print('Error: $error');
      print('StackTrace: $stackTrace');
    }
    // 这里可以添加错误上报逻辑
  }
}
