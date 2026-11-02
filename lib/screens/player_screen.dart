import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../models/movie.dart';
import '../services/vistara_api.dart';
import '../theme/app_theme.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    required this.movie,
    required this.api,
    required this.onRequireSignIn,
    required this.onViewPasses,
    super.key,
  });

  final Movie movie;
  final VistaraApi api;
  final Future<void> Function() onRequireSignIn;
  final VoidCallback onViewPasses;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _requiresSignIn = false;
  bool _requiresPass = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayback();
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleVideoChanged);
    unawaited(_controller?.dispose());
    super.dispose();
  }

  Future<void> _initializePlayback() async {
    final oldController = _controller;
    oldController?.removeListener(_handleVideoChanged);
    _controller = null;
    await oldController?.dispose();
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _requiresSignIn = false;
      _requiresPass = false;
      _error = null;
    });

    try {
      final session = await widget.api.restoreSession();
      if (session.user.accountStatus != 'ACTIVE') {
        throw const VistaraApiException(
          'This account cannot play films. Contact Vistara support.',
        );
      }
      if (session.entitlement == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _requiresPass = true;
            _error = 'An active Vistara access pass is required to watch.';
          });
        }
        return;
      }

      final controller = VideoPlayerController.networkUrl(
        widget.api.playbackUri(widget.movie.slug),
        httpHeaders: await widget.api.playbackHeaders(),
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      if (controller.value.hasError) {
        final message =
            controller.value.errorDescription ??
            'Vistara could not start playback. Try again.';
        await controller.dispose();
        throw VistaraApiException(message);
      }

      controller.addListener(_handleVideoChanged);
      setState(() {
        _controller = controller;
        _isLoading = false;
      });
    } on VistaraApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _requiresSignIn = error.statusCode == 401;
        _requiresPass = error.statusCode == 403;
        _error = error.statusCode == 401
            ? 'Sign in to watch this title.'
            : error.statusCode == 403
            ? 'An active Vistara access pass is required to watch.'
            : error.message;
      });
    } on PlatformException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Vistara could not start video playback. Try again later.';
      });
    }
  }

  void _handleVideoChanged() {
    final controller = _controller;
    if (!mounted || controller == null || !controller.value.hasError) return;

    setState(() {
      _error =
          controller.value.errorDescription ??
          'Video playback stopped unexpectedly.';
      _isLoading = false;
    });
  }

  Future<void> _signInAndRetry() async {
    await widget.onRequireSignIn();
    if (mounted) await _initializePlayback();
  }

  void _openPasses() {
    Navigator.of(context).pop();
    widget.onViewPasses();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.vistara;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(
          widget.movie.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildPlaybackError(context)
            : _buildVideoControls(context),
      ),
    );
  }

  Widget _buildPlaybackError(BuildContext context) {
    final palette = context.vistara;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _requiresPass ? Icons.lock_outline : Icons.movie_outlined,
              color: palette.accent,
              size: 44,
            ),
            const SizedBox(height: 16),
            Text(
              _requiresPass ? 'Access pass required' : 'Unable to play film',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (_requiresSignIn)
              FilledButton(
                onPressed: _signInAndRetry,
                child: const Text('Sign in'),
              )
            else if (_requiresPass)
              FilledButton(
                onPressed: _openPasses,
                child: const Text('View access passes'),
              )
            else
              OutlinedButton(
                onPressed: _initializePlayback,
                child: const Text('Try again'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoControls(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const Center(child: Text('Video player is unavailable.'));
    }

    final palette = context.vistara;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(controller),
                  ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: controller,
                    builder: (context, value, _) {
                      if (value.isPlaying) return const SizedBox.shrink();
                      return IconButton.filled(
                        tooltip: 'Play',
                        onPressed: controller.play,
                        style: IconButton.styleFrom(
                          backgroundColor: palette.accent,
                          foregroundColor: palette.onAccent,
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 36),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Column(
            children: [
              VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: palette.accent,
                  bufferedColor: palette.muted.withValues(alpha: 0.4),
                  backgroundColor: palette.line,
                ),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  return Row(
                    children: [
                      IconButton(
                        tooltip: value.isPlaying ? 'Pause' : 'Play',
                        onPressed: () {
                          if (value.isPlaying) {
                            controller.pause();
                          } else {
                            controller.play();
                          }
                        },
                        icon: Icon(
                          value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                      ),
                      Text(
                        '${_formatDuration(value.position)} / '
                        '${_formatDuration(value.duration)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Restart playback',
                        onPressed: () => controller.seekTo(Duration.zero),
                        icon: const Icon(Icons.replay_rounded),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
