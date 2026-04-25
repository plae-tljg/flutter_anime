import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final VoidCallback? onGoToSettings;

  const ErrorView({
    Key? key,
    required this.error,
    required this.onRetry,
    this.onGoToSettings,
  }) : super(key: key);

  bool get _isNetworkError =>
      error.contains('Failed host lookup') ||
      error.contains('SocketException') ||
      error.contains('Connection refused') ||
      error.contains('No address associated');

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isNetworkError ? Icons.wifi_off : Icons.error_outline,
              size: 64,
              color: _isNetworkError ? Colors.orange : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _isNetworkError ? 'Network Error' : 'Error',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isNetworkError
                  ? 'Could not reach anime source.\nThe site may be down or blocked.'
                  : error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (_isNetworkError && onGoToSettings != null) ...[
              const SizedBox(height: 8),
              Text(
                'Try switching to a different anime source',
                style: TextStyle(color: Colors.orange[700], fontSize: 12),
              ),
            ],
            const SizedBox(height: 24),
            if (_isNetworkError && onGoToSettings != null) ...[
              OutlinedButton.icon(
                onPressed: onGoToSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Switch Source'),
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}