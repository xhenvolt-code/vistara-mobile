import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../theme/app_theme.dart';

class MovieImage extends StatelessWidget {
  const MovieImage({
    required this.movie,
    required this.backdrop,
    required this.fit,
    super.key,
  });

  final Movie movie;
  final bool backdrop;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final remoteImage = backdrop
        ? movie.backdropUrl ?? movie.posterUrl
        : movie.posterUrl;
    final localImage = backdrop
        ? movie.backdropAsset ?? movie.posterAsset
        : movie.posterAsset;

    if (remoteImage != null && remoteImage.isNotEmpty) {
      return Image.network(
        remoteImage,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => const _ImagePlaceholder(),
      );
    }

    if (localImage != null && localImage.isNotEmpty) {
      return Image.asset(
        localImage,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => const _ImagePlaceholder(),
      );
    }

    return const _ImagePlaceholder();
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppTheme.surface,
      child: Center(
        child: Icon(Icons.movie_outlined, color: AppTheme.muted, size: 34),
      ),
    );
  }
}
