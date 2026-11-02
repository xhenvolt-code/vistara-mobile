import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vistara_mobile/models/access_product.dart';
import 'package:vistara_mobile/models/movie.dart';
import 'package:vistara_mobile/main.dart';
import 'package:vistara_mobile/screens/movie_details_screen.dart';
import 'package:vistara_mobile/screens/passes_screen.dart';
import 'package:vistara_mobile/services/vistara_api.dart';
import 'package:vistara_mobile/theme/app_theme.dart';

void main() {
  testWidgets('application follows the operating system brightness', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(_offlinePreviewApp());
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.light,
    );

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpWidget(
      VistaraApp(key: const ValueKey('dark-mode'), api: _offlineApi()),
    );
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.dark,
    );
  });

  testWidgets('home introduces the preview catalogue', (tester) async {
    await tester.pumpWidget(_offlinePreviewApp());

    expect(find.text('Movie lover'), findsOneWidget);
    expect(find.text('Preview catalogue'), findsOneWidget);
    expect(
      find.text('SAMPLE ARTWORK · NOT AVAILABLE TO WATCH'),
      findsOneWidget,
    );
  });

  testWidgets('catalogue search filters preview listings', (tester) async {
    await tester.pumpWidget(_offlinePreviewApp());
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
    await tester.pumpWidget(_offlinePreviewApp());
    await tester.tap(find.text('Subscriptions').last);
    await tester.pumpAndSettle();

    expect(find.text('Vistara server not configured'), findsOneWidget);
    expect(find.text('Checkout not enabled'), findsNothing);
    expect(find.text('UGX 1,500'), findsNothing);
  });

  testWidgets('subscription checkout requests MarzPay collection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var collectionRequested = false;
    final api = VistaraApi(
      baseUrl: 'https://vistara.example',
      sessionStore: _MemorySessionStore(),
      client: MockClient((request) async {
        expect(request.url.path, '/api/payments/marzpay/collections');
        expect(jsonDecode(request.body), {
          'productId': 'weekly-plan',
          'phoneNumber': '+256700000000',
        });
        collectionRequested = true;
        return http.Response(
          jsonEncode({
            'purchaseId': 'purchase-1',
            'status': 'PENDING',
            'message': 'Payment prompt requested.',
          }),
          201,
        );
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PassesScreen(
          products: const [
            AccessProduct(
              id: 'weekly-plan',
              name: 'Weekly plan',
              durationDays: 7,
              priceUgx: 4000,
            ),
          ],
          api: api,
          isConfigured: true,
          isSignedIn: true,
          isLoading: false,
          onRefreshAccount: () async {},
          onOpenAccount: () async {},
        ),
      ),
    );

    await tester.ensureVisible(find.text('Subscribe'));
    await tester.tap(find.text('Subscribe'));
    await tester.pumpAndSettle();
    expect(find.text('Weekly · 7 days'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '+256700000000');
    await tester.tap(find.text('Pay with MarzPay'));
    await tester.pumpAndSettle();

    expect(collectionRequested, isTrue);
    expect(find.text('Payment request sent'), findsOneWidget);
    expect(find.text('Payment prompt requested.'), findsOneWidget);
    expect(
      find.text(
        'Follow any mobile-money instructions. Do not retry while '
        'this payment is pending; access is granted only after '
        'server-side verification.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('sample movie detail clearly identifies preview-only artwork', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_offlinePreviewApp());
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

    expect(find.text('Subscription required'), findsOneWidget);
    expect(
      find.text('An active Vistara subscription is required to watch.'),
      findsOneWidget,
    );
    await tester.tap(find.text('View subscription plans'));
    await tester.pumpAndSettle();
    expect(openedPasses, isTrue);
  });

  testWidgets('account form does not claim to authenticate', (tester) async {
    await tester.pumpWidget(_offlinePreviewApp());
    await tester.tap(find.byIcon(Icons.person_outline_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Vistara server not configured'), findsOneWidget);
  });
}

VistaraApp _offlinePreviewApp() => VistaraApp(api: _offlineApi());

VistaraApi _offlineApi() =>
    VistaraApi(baseUrl: '', sessionStore: _MemorySessionStore());

class _MemorySessionStore implements VistaraSessionStore {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String value) async {}

  @override
  Future<void> delete() async {}

  @override
  Future<String?> readGoogleAuthState() async => null;

  @override
  Future<String?> readGoogleAuthVerifier() async => null;

  @override
  Future<void> writeGoogleAuthAttempt(String state, String verifier) async {}

  @override
  Future<void> deleteGoogleAuthAttempt() async {}
}
