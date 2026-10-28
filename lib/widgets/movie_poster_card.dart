import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../theme/app_theme.dart';
import 'movie_image.dart';

class MoviePosterCard extends StatelessWidget {
  const MoviePosterCard({
    required this.movie,
    required this.onTap,
    this.dense = false,
    super.key,
  });

  final Movie movie;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          '${movie.title}, ${movie.year ?? 'year to be announced'}, '
          '${movie.genre}${movie.isSample ? ', preview listing' : ''}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: dense ? 0.72 : 0.9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: MovieImage(
                  movie: movie,
                  backdrop: false,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: dense ? 6 : 10),
            Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFFF5F5F5),
                fontSize: dense ? 11 : 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!dense) ...[
              const SizedBox(height: 3),
              Text(
                '${movie.year ?? 'Year TBA'} · ${movie.genre}'
                '${movie.isSample ? ' · Preview' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.muted, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
