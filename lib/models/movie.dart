class Movie {
  const Movie({
    required this.id,
    required this.slug,
    required this.title,
    required this.year,
    required this.genre,
    this.posterAsset,
    this.backdropAsset,
    this.posterUrl,
    this.backdropUrl,
    this.synopsis,
    this.runtimeMinutes,
    this.language,
    this.isFeatured = false,
    this.isSample = false,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final slug = json['slug'];
    final title = json['title'];
    if (id is! String || slug is! String || title is! String) {
      throw const FormatException('The catalogue response is invalid.');
    }

    final genres = json['genres'];
    final genreNames = genres is List
        ? genres
              .map((genre) {
                if (genre is! Map<String, dynamic>) return null;
                final nestedGenre = genre['genre'];
                if (nestedGenre is Map<String, dynamic>) {
                  return nestedGenre['name'];
                }
                return genre['name'];
              })
              .whereType<String>()
              .toList(growable: false)
        : <String>[];
    final yearValue = json['releaseYear'];
    final runtimeValue = json['runtimeMinutes'];
    final posterUrlValue = json['posterUrl'];
    final backdropUrlValue = json['backdropUrl'];
    final synopsisValue = json['synopsis'];
    final languageValue = json['language'];
    final featuredValue = json['isFeatured'];

    return Movie(
      id: id,
      slug: slug,
      title: title,
      year: yearValue is int ? yearValue : null,
      genre: genreNames.isEmpty ? 'Film' : genreNames.join(', '),
      posterUrl: posterUrlValue is String ? posterUrlValue : null,
      backdropUrl: backdropUrlValue is String ? backdropUrlValue : null,
      synopsis: synopsisValue is String ? synopsisValue : null,
      runtimeMinutes: runtimeValue is int ? runtimeValue : null,
      language: languageValue is String ? languageValue : null,
      isFeatured: featuredValue is bool && featuredValue,
    );
  }

  final String id;
  final String slug;
  final String title;
  final int? year;
  final String genre;
  final String? posterAsset;
  final String? backdropAsset;
  final String? posterUrl;
  final String? backdropUrl;
  final String? synopsis;
  final int? runtimeMinutes;
  final String? language;
  final bool isFeatured;
  final bool isSample;
}
