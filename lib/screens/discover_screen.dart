import 'package:flutter/material.dart';

import '../data/demo_catalogue.dart';
import '../models/movie.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_poster_card.dart';
import '../widgets/preview_notice.dart';
import '../widgets/vistara_header.dart';
import 'movie_details_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({
    required this.onSignIn,
    required this.onViewPasses,
    required this.movies,
    required this.isPreview,
    this.onSearch,
    this.error,
    this.onRetry,
    this.displayName,
    super.key,
  });

  final VoidCallback onSignIn;
  final VoidCallback onViewPasses;
  final VoidCallback? onSearch;
  final List<Movie> movies;
  final bool isPreview;
  final String? error;
  final VoidCallback? onRetry;
  final String? displayName;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String _query = '';

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
    final movies = widget.isPreview
        ? searchCatalogue(_query)
        : widget.movies
              .where((movie) {
                final searchableText =
                    '${movie.title} ${movie.genre} ${movie.year ?? ''}'
                        .toLowerCase();
                return searchableText.contains(_query.trim().toLowerCase());
              })
              .toList(growable: false);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        VistaraHeader(
          onSignIn: widget.onSignIn,
          onSearch: widget.onSearch,
          displayName: widget.displayName,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Eyebrow('DISCOVER'),
              const SizedBox(height: 8),
              Text(
                'Find a film\nfor tonight.',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                widget.isPreview
                    ? 'Search sample titles. Vistara listings will appear '
                          'when the mobile app is connected to its catalogue.'
                    : 'Search films approved for distribution by the Vistara '
                          'team.',
                style: TextStyle(color: context.vistara.muted, height: 1.5),
              ),
              const SizedBox(height: 20),
              TextField(
                key: const ValueKey('catalogue-search'),
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Search titles or genres',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              if (widget.isPreview) ...[
                const SizedBox(height: 18),
                const PreviewNotice(
                  title: 'Preview artwork only',
                  message:
                      'These sample entries are not real Vistara listings '
                      'and are not available to stream.',
                ),
              ],
              const SizedBox(height: 24),
              if (widget.error != null)
                _CatalogueError(message: widget.error!, onRetry: widget.onRetry)
              else if (movies.isEmpty)
                _EmptyResults(query: _query, isPreview: widget.isPreview)
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 700
                        ? 4
                        : constraints.maxWidth >= 480
                        ? 3
                        : 2;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: movies.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 22,
                        childAspectRatio: 0.57,
                      ),
                      itemBuilder: (context, index) => MoviePosterCard(
                        movie: movies[index],
                        onTap: () => _openMovie(movies[index]),
                      ),
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

class _CatalogueError extends StatelessWidget {
  const _CatalogueError({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: TextStyle(color: context.vistara.muted)),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.query, required this.isPreview});

  final String query;
  final bool isPreview;

  @override
  Widget build(BuildContext context) {
    final message = query.isNotEmpty
        ? 'No titles match “$query”. Try another search.'
        : isPreview
        ? 'No sample titles to show.'
        : 'There are no titles available to stream yet.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        border: Border.all(color: context.vistara.line),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(message, style: TextStyle(color: context.vistara.muted)),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: context.vistara.accent,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.8,
      ),
    );
  }
}
