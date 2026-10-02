import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../app/app_colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key, required this.child});

  final Widget child;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late final VideoPlayerController _controller;
  Timer? _fallbackTimer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/splash.mp4');
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _fallbackTimer = Timer(const Duration(seconds: 5), _finish);

    try {
      await _controller.initialize();
      await _controller.setLooping(false);
      await _controller.setVolume(0);
      _controller.addListener(_handlePlayback);
      await _controller.play();

      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      _finish();
    }
  }

  void _handlePlayback() {
    final value = _controller.value;
    if (!value.isInitialized || value.duration == Duration.zero) return;

    if (value.isCompleted ||
        !value.isPlaying && value.position >= value.duration) {
      _finish();
    }
  }

  void _finish() {
    if (_finished || !mounted) return;
    _fallbackTimer?.cancel();
    setState(() => _finished = true);
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _controller.removeListener(_handlePlayback);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return widget.child;

    return ColoredBox(
      color: AppColors.background,
      child: _controller.value.isInitialized
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : const SizedBox.expand(),
    );
  }
}
