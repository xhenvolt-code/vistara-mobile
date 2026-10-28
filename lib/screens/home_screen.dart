import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_image.dart';
import '../widgets/movie_poster_card.dart';
import '../widgets/vistara_header.dart';
import 'movie_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.onSignIn,
    required this.onExplore,
    required this.onViewPasses,
    required this.movies,
    required this.isPreview,
    required this.isLoading,
    required this.displayName,
    this.error,
    this.onRetry,
    super.key,
  });

  final VoidCallback onSignIn;
  final VoidCallback onExplore;
  final VoidCallback onViewPasses;
  final List<Movie> movies;
  final bool isPreview;
  final bool isLoading;
  final String? displayName;
  final String? error;
  final VoidCallback? onRetry;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _featuredController = PageController(viewportFraction: 0.87);
  int _featuredIndex = 0;

  @override
  void dispose() {
    _featuredController.dispose();
    super.dispose();
  }

  void _openMovie(Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MovieDetailsScreen(
          movie: movie,
          catalogue: widget.movies,
          onViewPasses: widget.onViewPasses,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 26),
      children: [
        VistaraHeader(
          onSignIn: widget.onSignIn,
          onSearch: widget.onExplore,
          displayName: widget.displayName,
        ),
        if (widget.isLoading)
          const SizedBox(
            height: 212,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (widget.error != null)
          _HomeLoadError(message: widget.error!, onRetry: widget.onRetry)
        else if (widget.movies.isNotEmpty) ...[
          SizedBox(
            height: 184,
            child: PageView.builder(
              controller: _featuredController,
              itemCount: widget.movies.length,
              onPageChanged: (index) => setState(() => _featuredIndex = index),
              itemBuilder: (context, index) {
                final movie = widget.movies[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _FeaturedMovieCard(
                    movie: movie,
                    onTap: () => _openMovie(movie),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.movies.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: index == _featuredIndex ? 14 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: index == _featuredIndex
                        ? AppTheme.accent
                        : const Color(0xFF55565A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppTheme.accent,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.isPreview
                        ? 'SAMPLE ARTWORK · NOT AVAILABLE TO WATCH'
                        : 'VISTARA SELECTION · PLAYBACK NOT AVAILABLE',
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.75,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _SectionHeading(
            title: widget.isPreview
                ? 'Preview catalogue'
                : 'Featured on Vistara',
            actionLabel: 'See all',
            onTap: widget.onExplore,
          ),
          SizedBox(
            height: 204,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: widget.movies.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final movie = widget.movies[index];
                return SizedBox(
                  width: 108,
                  child: MoviePosterCard(
                    movie: movie,
                    dense: true,
                    onTap: () => _openMovie(movie),
                  ),
                );
              },
            ),
          ),
        ] else ...[
          _EmptyCatalogue(
            isPreview: widget.isPreview,
            onExplore: widget.onExplore,
          ),
        ],
        if (widget.isPreview)
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 6),
            child: Text(
              'Stories worth staying in for.  ·  Uganda · UGX',
              style: TextStyle(color: AppTheme.muted, fontSize: 11),
            ),
          ),
      ],
    );
  }
}

class _HomeLoadError extends StatelessWidget {
  const _HomeLoadError({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(message, style: const TextStyle(color: AppTheme.muted)),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class _EmptyCatalogue extends StatelessWidget {
  const _EmptyCatalogue({required this.isPreview, required this.onExplore});

  final bool isPreview;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPreview
                ? 'No sample titles to show.'
                : 'No titles available yet.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (!isPreview) ...[
            const SizedBox(height: 8),
            const Text(
              'Films will appear here after they have been approved for '
              'distribution.',
              style: TextStyle(color: AppTheme.muted, height: 1.5),
            ),
            TextButton(onPressed: onExplore, child: const Text('Refresh')),
          ],
        ],
      ),
    );
  }
}

class _FeaturedMovieCard extends StatelessWidget {
  const _FeaturedMovieCard({required this.movie, required this.onTap});

  final Movie movie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          'Featured ${movie.isSample ? 'preview ' : ''}'
          '${movie.title}, ${movie.genre}, ${movie.year ?? 'year TBA'}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              MovieImage(movie: movie, backdrop: true, fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x22000000), Color(0xDD000000)],
                    stops: [0.25, 1],
                  ),
                ),
              ),
              Positioned(
                left: 13,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    movie.isSample ? 'PREVIEW' : 'VISTARA',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 12,
                bottom: 12,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            movie.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${movie.year ?? 'Year TBA'}  ·  ${movie.genre}',
                            style: const TextStyle(
                              color: Color(0xFFD4D4D5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.accent,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            child: Text(actionLabel, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
