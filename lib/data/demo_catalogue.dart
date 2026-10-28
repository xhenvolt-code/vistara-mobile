import '../models/movie.dart';

const demoCatalogue = <Movie>[
  Movie(
    id: 'sample-01',
    slug: 'sample-01',
    title: 'Sample title 01',
    year: 2025,
    genre: 'Adventure',
    posterAsset: 'assets/images/movies/movie-1-1290x1290.jpg',
    backdropAsset: 'assets/images/movies/movie-1-3840x2160.jpg',
    isSample: true,
  ),
  Movie(
    id: 'sample-02',
    slug: 'sample-02',
    title: 'Sample title 02',
    year: 2024,
    genre: 'Drama',
    posterAsset: 'assets/images/movies/movie-2-1290x1290.jpg',
    backdropAsset: 'assets/images/movies/movie-2-3840x2160.jpg',
    isSample: true,
  ),
  Movie(
    id: 'sample-03',
    slug: 'sample-03',
    title: 'Sample title 03',
    year: 2025,
    genre: 'Thriller',
    posterAsset: 'assets/images/movies/movie-3-1290x1290.jpg',
    backdropAsset: 'assets/images/movies/movie-3-3840x2160.jpg',
    isSample: true,
  ),
  Movie(
    id: 'sample-04',
    slug: 'sample-04',
    title: 'Sample title 04',
    year: 2023,
    genre: 'Action',
    posterAsset: 'assets/images/movies/movie-4-1290x1290.jpg',
    isSample: true,
  ),
  Movie(
    id: 'sample-05',
    slug: 'sample-05',
    title: 'Sample title 05',
    year: 2024,
    genre: 'Mystery',
    posterAsset: 'assets/images/movies/movie-5-1290x1290.jpg',
    isSample: true,
  ),
];

List<Movie> searchCatalogue(String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return demoCatalogue;

  return demoCatalogue
      .where((movie) {
        final searchableText = '${movie.title} ${movie.genre} ${movie.year}'
            .toLowerCase();
        return searchableText.contains(normalizedQuery);
      })
      .toList(growable: false);
}
