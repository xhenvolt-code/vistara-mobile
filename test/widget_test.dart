import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vistara_mobile/models/movie.dart';
import 'package:vistara_mobile/main.dart';
import 'package:vistara_mobile/screens/movie_details_screen.dart';
import 'package:vistara_mobile/services/vistara_api.dart';
import 'package:vistara_mobile/theme/app_theme.dart';

void main() {
  testWidgets('application follows the operating system brightness', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const VistaraApp());
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.light,
    );

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpWidget(const VistaraApp(key: ValueKey('dark-mode')));
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.dark,
    );
  });

  testWidgets('home introduces the preview catalogue', (tester) async {
    await tester.pumpWidget(const VistaraApp());

    expect(find.text('Movie lover'), findsOneWidget);
    expect(find.text('Preview catalogue'), findsOneWidget);
    expect(
      find.text('SAMPLE ARTWORK · NOT AVAILABLE TO WATCH'),
      findsOneWidget,
    );
  });

  testWidgets('catalogue search filters preview listings', (tester) async {
    await tester.pumpWidget(const VistaraApp());
    await tester.tap(find.text('Discover').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('catalogue-search')),
      'adventure',
    );
    await tester.pumpAndSettle();

    expect(find.text('Sample title 01'), findsOneWidget);
    expect(find.text('Sample title 02'), findsNothing);
  });

  testWidgets('offline passes never show fabricated prices', (tester) async {
    await tester.pumpWidget(const VistaraApp());
    await tester.tap(find.text('Passes').last);
    await tester.pumpAndSettle();

    expect(find.text('Vistara server not configured'), findsOneWidget);
    expect(find.text('Checkout not enabled'), findsOneWidget);
    expect(find.text('UGX 1,500'), findsNothing);
  });

  testWidgets('sample movie detail clearly identifies preview-only artwork', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const VistaraApp());
    await tester.tap(find.text('Discover').last);
    await tester.pumpAndSettle();

    final firstMovie = find.text('Sample title 01');
    await tester.ensureVisible(firstMovie);
    await tester.tap(firstMovie);
    await tester.pumpAndSettle();

    expect(find.text('Preview only'), findsNWidgets(2));
    expect(
      find.text(
        'This is template sample artwork. No film, rights '
        'approval, or playback asset is attached to this preview listing.',
      ),
      findsOneWidget,
    );
    final previewButton = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Preview only').first,
        matching: find.byType(FilledButton),
      ),
    );
    expect(previewButton.onPressed, isNull);
  });

  testWidgets('protected playback directs signed-out viewers to sign in', (
    tester,
  ) async {
    final api = VistaraApi(
      baseUrl: 'https://vistara.example',
      sessionStore: _MemorySessionStore(),
      client: MockClient(
        (_) async => http.Response(jsonEncode({'error': 'Unauthorized'}), 401),
      ),
    );
    final movie = Movie(
      id: 'film-1',
      slug: 'night-road',
      title: 'Night Road',
      year: 2026,
      genre: 'Drama',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MovieDetailsScreen(
          movie: movie,
          catalogue: [movie],
          onViewPasses: () {},
          api: api,
          isPreview: false,
          onRequireSignIn: () async {},
        ),
      ),
    );

    await tester.tap(find.text('Watch film'));
    await tester.pumpAndSettle();

    expect(find.text('Unable to play film'), findsOneWidget);
    expect(find.text('Sign in to watch this title.'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('protected playback directs viewers without a pass to passes', (
    tester,
  ) async {
    final api = VistaraApi(
      baseUrl: 'https://vistara.example',
      sessionStore: _MemorySessionStore(),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'user': {
              'id': 'viewer-1',
              'email': 'viewer@example.com',
              'name': 'Viewer',
              'accountStatus': 'ACTIVE',
            },
            'entitlement': null,
            'purchases': [],
          }),
          200,
        ),
      ),
    );
    final movie = Movie(
      id: 'film-1',
      slug: 'night-road',
      title: 'Night Road',
      year: 2026,
      genre: 'Drama',
    );
    var openedPasses = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MovieDetailsScreen(
          movie: movie,
          catalogue: [movie],
          onViewPasses: () => openedPasses = true,
          api: api,
          isPreview: false,
          onRequireSignIn: () async {},
        ),
      ),
    );

    await tester.tap(find.text('Watch film'));
    await tester.pumpAndSettle();

    expect(find.text('Access pass required'), findsOneWidget);
    expect(find.text('An active Vistara access pass is required to watch.'),
        findsOneWidget);
    await tester.tap(find.text('View access passes'));
    await tester.pumpAndSettle();
    expect(openedPasses, isTrue);
  });

  testWidgets('account form does not claim to authenticate', (tester) async {
    await tester.pumpWidget(const VistaraApp());
    await tester.tap(find.byIcon(Icons.person_outline_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Vistara server not configured'), findsOneWidget);
  });
}

class _MemorySessionStore implements VistaraSessionStore {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String value) async {}

  @override
  Future<void> delete() async {}
}
