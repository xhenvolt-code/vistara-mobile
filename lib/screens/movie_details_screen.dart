import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_image.dart';
import '../widgets/movie_poster_card.dart';
import '../widgets/preview_notice.dart';
import 'player_screen.dart';

class MovieDetailsScreen extends StatefulWidget {
  const MovieDetailsScreen({
    required this.movie,
    required this.catalogue,
    required this.onViewPasses,
    super.key,
  });

  final Movie movie;
  final List<Movie> catalogue;
  final VoidCallback onViewPasses;

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  bool _isSaved = false;

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final relatedMovies = widget.catalogue
        .where((entry) => entry.id != movie.id)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(movie.isSample ? 'Preview listing' : 'Film details'),
        actions: [
          IconButton(
            tooltip: _isSaved ? 'Remove from saved' : 'Save film',
            onPressed: () => setState(() => _isSaved = !_isSaved),
            icon: Icon(
              _isSaved ? Icons.favorite : Icons.favorite_border,
              color: _isSaved ? AppTheme.accent : Colors.white,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 330,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MovieImage(movie: movie, backdrop: true, fit: BoxFit.cover),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), AppTheme.background],
                      stops: [0.35, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          movie.isSample
                              ? 'PREVIEW LISTING'
                              : 'VISTARA SELECTION',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        movie.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${movie.year ?? 'Year TBA'}  ·  ${movie.genre}'
                  '${movie.runtimeMinutes == null ? '' : '  ·  ${movie.runtimeMinutes} min'}'
                  '${movie.language == null || movie.language!.isEmpty ? '' : '  ·  ${movie.language}'}',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PlayerScreen(movie: movie),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Playback unavailable'),
                  ),
                ),
                const SizedBox(height: 14),
                PreviewNotice(
                  title: 'Playback not available',
                  message: movie.isSample
                      ? 'This is template sample artwork. No film, rights '
                            'approval, or playback asset is attached to this '
                            'preview listing.'
                      : 'Playback is not yet available for this title. '
                            'Please check back later.',
                ),
                const SizedBox(height: 24),
                const Text(
                  'Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  movie.synopsis ??
                      (movie.isSample
                          ? 'This sample title is for catalogue layout '
                                'development only. A film description has not '
                                'been added.'
                          : 'A description has not been added for this film.'),
                  style: const TextStyle(color: AppTheme.muted, height: 1.5),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onViewPasses();
                  },
                  child: const Text('View available access passes'),
                ),
                if (relatedMovies.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'More like this',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 198,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: relatedMovies.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final relatedMovie = relatedMovies[index];
                        return SizedBox(
                          width: 110,
                          child: MoviePosterCard(
                            movie: relatedMovie,
                            dense: true,
                            onTap: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute<void>(
                                  builder: (_) => MovieDetailsScreen(
                                    movie: relatedMovie,
                                    catalogue: widget.catalogue,
                                    onViewPasses: widget.onViewPasses,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
