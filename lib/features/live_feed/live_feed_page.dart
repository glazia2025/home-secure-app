import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

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
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  LiveFeedSignalingSession? _signaling;
  StreamSubscription<Map<String, dynamic>>? _signalSubscription;
  RTCPeerConnection? _peerConnection;
  final List<RTCIceCandidate> _pendingCandidates = <RTCIceCandidate>[];
  Object? _error;
  String _status = 'connecting';
  bool _remoteDescriptionSet = false;
  bool _disposed = false;
  int _connectionGeneration = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_initialise());
  }

  Future<void> _initialise() async {
    await _renderer.initialize();
    if (!_disposed) await _connect();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_closeConnection());
    unawaited(_renderer.dispose());
    super.dispose();
  }

  Future<void> _connect() async {
    final generation = ++_connectionGeneration;
    final repository = context.read<AppRepository>();
    await _closeConnection();
    if (!mounted || generation != _connectionGeneration) return;
    setState(() {
      _error = null;
      _status = 'connecting';
    });

    try {
      final peer = await createPeerConnection(<String, dynamic>{
        'iceServers': <Map<String, dynamic>>[
          <String, dynamic>{
            'urls': <String>['stun:stun.l.google.com:19302'],
          },
        ],
        'sdpSemantics': 'unified-plan',
      });
      if (_disposed || generation != _connectionGeneration) {
        await peer.close();
        return;
      }
      _peerConnection = peer;
      await peer.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      peer.onTrack = (RTCTrackEvent event) {
        if (_disposed || generation != _connectionGeneration) return;
        final stream = event.streams.isNotEmpty ? event.streams.first : null;
        if (stream != null) _renderer.srcObject = stream;
      };
      peer.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate.candidate == null || candidate.candidate!.isEmpty) return;
        _signaling?.send(<String, dynamic>{
          'type': 'ice-candidate',
          'candidate': candidate.toMap(),
        });
      };
      peer.onConnectionState = (RTCPeerConnectionState state) {
        if (!mounted || _disposed || generation != _connectionGeneration) {
          return;
        }
        setState(() {
          switch (state) {
            case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
              _status = 'live';
            case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
              _status = 'offline';
              _error = 'WebRTC connection failed';
            case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
              _status = 'offline';
            default:
              break;
          }
        });
      };

      final signaling = await repository.liveFeedSignalingSession(widget.home);
      if (_disposed || generation != _connectionGeneration) {
        await signaling.close();
        return;
      }
      _signaling = signaling;
      _signalSubscription = signaling.messages.listen(
        (message) => _handleSignal(message, generation),
        onError: (Object error) => _setFailure(error, generation),
        onDone: () => _setFailure('Signaling connection closed', generation),
        cancelOnError: true,
      );
    } catch (error) {
      _setFailure(error, generation);
    }
  }

  Future<void> _handleSignal(
    Map<String, dynamic> message,
    int generation,
  ) async {
    if (_disposed || generation != _connectionGeneration) return;
    try {
      switch (message['type']) {
        case 'ready':
        case 'status':
          if (message['status'] == 'offline' && mounted) {
            setState(() => _status = 'waiting');
          }
        case 'offer':
          final sdp = _map(message['sdp']);
          final peer = _peerConnection;
          if (peer == null || sdp == null) return;
          await peer.setRemoteDescription(
            RTCSessionDescription(
              sdp['sdp'] as String?,
              sdp['type'] as String?,
            ),
          );
          _remoteDescriptionSet = true;
          for (final candidate in _pendingCandidates) {
            await peer.addCandidate(candidate);
          }
          _pendingCandidates.clear();
          final answer = await peer.createAnswer(<String, dynamic>{});
          await peer.setLocalDescription(answer);
          _signaling?.send(<String, dynamic>{
            'type': 'answer',
            'sdp': answer.toMap(),
          });
          if (mounted) setState(() => _status = 'connecting');
        case 'ice-candidate':
          final json = _map(message['candidate']);
          if (json == null) return;
          final candidate = RTCIceCandidate(
            json['candidate'] as String?,
            json['sdpMid'] as String?,
            (json['sdpMLineIndex'] as num?)?.toInt(),
          );
          if (_remoteDescriptionSet) {
            await _peerConnection?.addCandidate(candidate);
          } else {
            _pendingCandidates.add(candidate);
          }
        case 'error':
          _setFailure(
            message['message'] ?? 'WebRTC signaling failed',
            generation,
          );
      }
    } catch (error) {
      _setFailure(error, generation);
    }
  }

  Map<String, dynamic>? _map(dynamic value) {
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  void _setFailure(Object error, int generation) {
    if (!mounted || _disposed || generation != _connectionGeneration) return;
    setState(() {
      _error = error;
      _status = 'offline';
    });
  }

  Future<void> _closeConnection() async {
    await _signalSubscription?.cancel();
    _signalSubscription = null;
    await _signaling?.close();
    _signaling = null;
    _renderer.srcObject = null;
    await _peerConnection?.close();
    _peerConnection = null;
    _pendingCandidates.clear();
    _remoteDescriptionSet = false;
  }

  @override
  Widget build(BuildContext context) {
    final isLive = _status == 'live';
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
                    StatusPill(label: isLive ? 'online' : _status),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(
                          color: Colors.black,
                          child: RTCVideoView(
                            _renderer,
                            objectFit: RTCVideoViewObjectFit
                                .RTCVideoViewObjectFitCover,
                          ),
                        ),
                        if (!isLive)
                          _WaitingFeed(
                            status: _status,
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
            title: 'ESP32 WebRTC stream',
            icon: Icons.memory_outlined,
            child: Text(
              'The ESP32 sends video directly to this device over WebRTC. The backend WebSocket is used only to authenticate and exchange SDP and ICE candidates.',
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
                status == 'waiting'
                    ? 'Waiting for the ESP32 camera'
                    : 'Connecting WebRTC video...',
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
