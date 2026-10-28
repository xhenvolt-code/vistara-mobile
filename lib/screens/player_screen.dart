import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../theme/app_theme.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({required this.movie, super.key});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.vistara.background,
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
                    icon: Icon(
                      Icons.close,
                      color: context.vistara.onBackground,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      movie.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.vistara.onBackground,
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
                        Icon(
                          Icons.movie_outlined,
                          color: context.vistara.muted,
                          size: 44,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Playback unavailable',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.vistara.onBackground,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No video is attached to this sample listing: '
                          '${movie.title}.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.vistara.muted,
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
                  Expanded(
                    child: LinearProgressIndicator(
                      value: 0,
                      minHeight: 2,
                      backgroundColor: context.vistara.line,
                      color: context.vistara.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '--:--',
                    style: TextStyle(
                      color: context.vistara.onBackground,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'PREVIEW PLAYER · NO VIDEO AVAILABLE',
                  style: TextStyle(
                    color: context.vistara.muted,
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
