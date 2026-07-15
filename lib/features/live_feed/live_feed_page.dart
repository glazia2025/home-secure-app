import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../../app/app_colors.dart';
import '../../data/app_repository.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/cards.dart';

class LiveFeedPage extends StatefulWidget {
  const LiveFeedPage({super.key, required this.home});

  final Home home;

  @override
  State<LiveFeedPage> createState() => _LiveFeedPageState();
}

class _LiveFeedPageState extends State<LiveFeedPage> {
  Uri? _streamUri;
  Uint8List? _frame;
  http.Client? _streamClient;
  StreamSubscription<List<int>>? _streamSubscription;
  Object? _error;
  bool _loading = true;
  bool _disposed = false;
  bool _collectingFrame = false;
  int _previousByte = -1;
  int _connectionGeneration = 0;
  List<int> _frameBuffer = <int>[];

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    _disposed = true;
    _closeStream();
    super.dispose();
  }

  Future<void> _connect() async {
    final generation = ++_connectionGeneration;
    _closeStream();
    setState(() {
      _loading = true;
      _error = null;
      _streamUri = null;
      _frame = null;
    });

    try {
      final uri = await context.read<AppRepository>().mjpegLiveFeedUri(
        widget.home,
      );
      if (!mounted) return;
      setState(() {
        _streamUri = uri;
      });
      await _openMjpegStream(uri, generation);
    } catch (error) {
      if (!mounted || generation != _connectionGeneration) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _openMjpegStream(Uri uri, int generation) async {
    final client = http.Client();
    _streamClient = client;

    final request = http.Request('GET', uri);
    final response = await client.send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Camera stream failed with status ${response.statusCode}',
      );
    }

    _streamSubscription = response.stream.listen(
      (chunk) => _handleStreamChunk(chunk, generation),
      onError: (Object error) {
        if (!mounted || _disposed || generation != _connectionGeneration) {
          return;
        }
        setState(() {
          _error = error;
          _loading = false;
        });
      },
      onDone: () {
        if (!mounted || _disposed || generation != _connectionGeneration) {
          return;
        }
        setState(() {
          _error ??= 'Camera stream closed';
          _loading = false;
        });
      },
      cancelOnError: true,
    );
  }

  void _handleStreamChunk(List<int> chunk, int generation) {
    if (generation != _connectionGeneration) return;
    for (final byte in chunk) {
      if (!_collectingFrame) {
        if (_previousByte == 0xff && byte == 0xd8) {
          _collectingFrame = true;
          _frameBuffer = <int>[0xff, 0xd8];
        }
        _previousByte = byte;
        continue;
      }

      _frameBuffer.add(byte);
      if (_frameBuffer.length > 400 * 1024) {
        _resetFrameParser(byte);
        continue;
      }

      if (_previousByte == 0xff && byte == 0xd9) {
        final frame = Uint8List.fromList(_frameBuffer);
        _resetFrameParser(byte);
        if (!mounted || _disposed || generation != _connectionGeneration) {
          return;
        }
        setState(() {
          _frame = frame;
          _loading = false;
          _error = null;
        });
        continue;
      }
      _previousByte = byte;
    }
  }

  void _resetFrameParser(int previousByte) {
    _collectingFrame = false;
    _frameBuffer = <int>[];
    _previousByte = previousByte;
  }

  void _closeStream() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _streamClient?.close();
    _streamClient = null;
    _resetFrameParser(-1);
  }

  @override
  Widget build(BuildContext context) {
    final isLive = _streamUri != null && !_loading && _error == null;

    return Scaffold(
      appBar: AppBar(title: const Text('Main Door Live Feed')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SectionCard(
            title: widget.home.name,
            icon: Icons.videocam_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Main door camera',
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    StatusPill(label: isLive ? 'online' : 'offline'),
                  ],
                ),
                const SizedBox(height: 14),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_frame != null)
                          Image.memory(
                            _frame!,
                            fit: BoxFit.cover,
                            gaplessPlayback: false,
                          ),
                        if (_loading || _frame == null)
                          _WaitingFeed(
                            status: _loading ? 'connecting' : 'offline',
                            message: _error?.toString(),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  ErrorBanner(message: _error.toString()),
                ],
                const SizedBox(height: 16),
                AppButton(
                  label: 'Reconnect',
                  icon: Icons.refresh,
                  outlined: true,
                  onPressed: _connect,
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'ESP32 MJPEG stream',
            icon: Icons.memory_outlined,
            child: Text(
              'The app opens an MJPEG stream from the backend. The ESP32 sends JPEG frames as binary messages over /api/device/hubs/control/ws.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingFeed extends StatelessWidget {
  const _WaitingFeed({required this.status, this.message});

  final String status;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.78),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off_outlined,
                color: AppColors.accent,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                status == 'connecting'
                    ? 'Connecting to MJPEG camera...'
                    : 'Waiting for ESP32 MJPEG stream',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (message != null && message!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
