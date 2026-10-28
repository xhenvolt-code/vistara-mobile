import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../theme/app_theme.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({required this.movie, super.key});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Close preview player',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      movie.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Subtitles unavailable',
                    onPressed: null,
                    icon: const Icon(Icons.closed_caption_outlined),
                  ),
                  IconButton(
                    tooltip: 'Audio unavailable',
                    onPressed: null,
                    icon: const Icon(Icons.volume_up_outlined),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.movie_outlined,
                          color: Color(0xFF606166),
                          size: 44,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Playback unavailable',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No video is attached to this sample listing: '
                          '${movie.title}.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.muted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Playback unavailable',
                    onPressed: null,
                    icon: const Icon(Icons.play_arrow_rounded),
                  ),
                  const Expanded(
                    child: LinearProgressIndicator(
                      value: 0,
                      minHeight: 2,
                      backgroundColor: Color(0xFF434449),
                      color: AppTheme.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '--:--',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'PREVIEW PLAYER · NO VIDEO AVAILABLE',
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
