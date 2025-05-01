import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class LocalVideoPlayerScreen extends StatefulWidget {
  final List<FileSystemEntity> videoFiles;
  final int initialIndex;

  const LocalVideoPlayerScreen({
    Key? key,
    required this.videoFiles,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<LocalVideoPlayerScreen> createState() => _LocalVideoPlayerScreenState();
}

class _LocalVideoPlayerScreenState extends State<LocalVideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _showControls = true;
  double _currentSpeed = 1.0;
  int _currentIndex = 0;
  final List<double> _availableSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    await _controller?.dispose();
    _controller =
        VideoPlayerController.file(File(widget.videoFiles[_currentIndex].path));
    await _controller!.initialize();
    _controller!.addListener(_videoListener);
    setState(() {});
  }

  void _videoListener() {
    if (_controller?.value.isPlaying != _isPlaying) {
      setState(() {
        _isPlaying = _controller?.value.isPlaying ?? false;
      });
    }
  }

  void _playNextVideo() {
    if (_currentIndex < widget.videoFiles.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _initializePlayer();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已经是最后一个视频')),
      );
    }
  }

  void _playPreviousVideo() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _initializePlayer();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已经是第一个视频')),
      );
    }
  }

  void _togglePlayPause() {
    if (_controller != null) {
      setState(() {
        _isPlaying ? _controller!.pause() : _controller!.play();
      });
    }
  }

  void _seekForward() {
    if (_controller != null) {
      final newPosition =
          _controller!.value.position + const Duration(seconds: 10);
      _controller!.seekTo(newPosition);
    }
  }

  void _seekBackward() {
    if (_controller != null) {
      final newPosition =
          _controller!.value.position - const Duration(seconds: 10);
      _controller!.seekTo(newPosition);
    }
  }

  void _changeSpeed() {
    if (_controller != null) {
      final currentIndex = _availableSpeeds.indexOf(_currentSpeed);
      final nextIndex = (currentIndex + 1) % _availableSpeeds.length;
      setState(() {
        _currentSpeed = _availableSpeeds[nextIndex];
        _controller!.setPlaybackSpeed(_currentSpeed);
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Stack(
          children: [
            // 视频播放器
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
            // 控制层
            if (_showControls)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      title: Text(
                        widget.videoFiles[_currentIndex].path.split('/').last,
                        style: const TextStyle(color: Colors.white),
                      ),
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ValueListenableBuilder(
                            valueListenable: _controller!,
                            builder: (context, VideoPlayerValue value, child) {
                              return Column(
                                children: [
                                  Slider(
                                    value: value.position.inMilliseconds
                                        .toDouble(),
                                    min: 0,
                                    max: value.duration.inMilliseconds
                                        .toDouble(),
                                    onChanged: (newValue) {
                                      _controller!.seekTo(Duration(
                                          milliseconds: newValue.toInt()));
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDuration(value.position),
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        Text(
                                          _formatDuration(value.duration),
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.skip_previous,
                                    color: Colors.white),
                                onPressed: _playPreviousVideo,
                              ),
                              IconButton(
                                icon: const Icon(Icons.replay_10,
                                    color: Colors.white),
                                onPressed: _seekBackward,
                              ),
                              IconButton(
                                icon: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                onPressed: _togglePlayPause,
                              ),
                              IconButton(
                                icon: const Icon(Icons.forward_10,
                                    color: Colors.white),
                                onPressed: _seekForward,
                              ),
                              IconButton(
                                icon: const Icon(Icons.skip_next,
                                    color: Colors.white),
                                onPressed: _playNextVideo,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${_currentIndex + 1}/${widget.videoFiles.length}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: Text(
                                  '${_currentSpeed}x',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                onPressed: _changeSpeed,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
