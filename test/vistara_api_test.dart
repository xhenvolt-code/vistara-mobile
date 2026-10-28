import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vistara_mobile/models/access_product.dart';
import 'package:vistara_mobile/services/vistara_api.dart';

void main() {
  test('catalogue response maps approved film metadata and genres', () async {
    final api = VistaraApi(
      baseUrl: 'https://vistara.example',
      sessionStore: _MemorySessionStore(),
      client: MockClient((request) async {
        expect(request.url.path, '/api/mobile/catalogue');
        return http.Response(
          jsonEncode({
            'movies': [
              {
                'id': 'film-1',
                'slug': 'night-road',
                'title': 'Night Road',
                'synopsis': 'A journey home.',
                'posterUrl': 'https://images.example/poster.jpg',
                'backdropUrl': 'https://images.example/backdrop.jpg',
                'releaseYear': 2026,
                'runtimeMinutes': 95,
                'language': 'English',
                'isFeatured': true,
                'genres': [
                  {
                    'genre': {'name': 'Drama'},
                  },
                ],
              },
            ],
          }),
          200,
        );
      }),
    );

    final movies = await api.loadCatalogue();

    expect(movies, hasLength(1));
    expect(movies.single.title, 'Night Road');
    expect(movies.single.year, 2026);
    expect(movies.single.genre, 'Drama');
    expect(movies.single.posterUrl, 'https://images.example/poster.jpg');
    expect(movies.single.isFeatured, isTrue);
    expect(movies.single.isSample, isFalse);
  });

  test('active pass response maps the server-managed product', () async {
    final api = VistaraApi(
      baseUrl: 'https://vistara.example',
      sessionStore: _MemorySessionStore(),
      client: MockClient((request) async {
        expect(request.url.path, '/api/mobile/access-products');
        return http.Response(
          jsonEncode({
            'products': [
              {
                'id': 'pass-7-day',
                'name': '7 day pass',
                'durationDays': 7,
                'priceUgx': 4000,
              },
            ],
          }),
          200,
        );
      }),
    );

    final products = await api.loadAccessProducts();

    expect(products, hasLength(1));
    expect(products.single, isA<AccessProduct>());
    expect(products.single.priceUgx, 4000);
    expect(products.single.durationDays, 7);
  });

  test(
    'sign-in stores the secure cookie and restores the account session',
    () async {
      final store = _MemorySessionStore();
      var sessionRequestCount = 0;
      final api = VistaraApi(
        baseUrl: 'https://vistara.example',
        sessionStore: store,
        client: MockClient((request) async {
          if (request.url.path == '/api/auth/sign-in/email') {
            expect(request.headers['origin'], 'https://vistara.example');
            expect(jsonDecode(request.body), {
              'email': 'viewer@example.com',
              'password': 'correct horse',
            });
            return http.Response(
              jsonEncode({'token': 'session-token'}),
              200,
              headers: {
                'set-cookie':
                    'vistara.session=opaque-token; Path=/; HttpOnly; Secure; '
                    'SameSite=Lax',
              },
            );
          }

          expect(request.url.path, '/api/mobile/session');
          expect(request.headers['cookie'], 'vistara.session=opaque-token');
          sessionRequestCount++;
          return http.Response(
            jsonEncode({
              'user': {
                'id': 'user-1',
                'email': 'viewer@example.com',
                'name': 'Vistara Viewer',
                'accountStatus': 'ACTIVE',
              },
              'entitlement': {
                'startsAt': '2026-10-27T00:00:00.000Z',
                'expiresAt': '2026-11-03T00:00:00.000Z',
                'purchase': {'productName': '7 day pass'},
              },
              'purchases': [
                {
                  'id': 'purchase-1',
                  'productName': '7 day pass',
                  'amountUgx': 4000,
                  'currency': 'UGX',
                  'status': 'PAID',
                  'createdAt': '2026-10-27T00:00:00.000Z',
                },
              ],
            }),
            200,
          );
        }),
      );

      final session = await api.signIn(
        email: ' Viewer@Example.com ',
        password: 'correct horse',
      );

      expect(session.user.name, 'Vistara Viewer');
      expect(session.entitlement?.productName, '7 day pass');
      expect(session.purchases.single.status, 'PAID');
      expect(sessionRequestCount, 1);
      expect(store.value, contains('opaque-token'));
    },
  );

  test('expired sessions clear the local session cookie', () async {
    final store = _MemorySessionStore()
      ..value = jsonEncode({
        'origin': 'https://vistara.example',
        'cookies': {
          'vistara.session': {'value': 'expired', 'secure': true},
        },
      });
    final api = VistaraApi(
      baseUrl: 'https://vistara.example',
      sessionStore: store,
      client: MockClient(
        (_) async => http.Response(jsonEncode({'error': 'Unauthorized'}), 401),
      ),
    );

    await expectLater(
      api.restoreSession(),
      throwsA(isA<VistaraApiException>()),
    );
    expect(store.value, isNull);
  });

  test('unconfigured API fails with setup guidance, not fake data', () async {
    final api = VistaraApi(sessionStore: _MemorySessionStore());

    expect(api.isConfigured, isFalse);
    await expectLater(
      api.loadCatalogue(),
      throwsA(
        isA<VistaraApiException>().having(
          (error) => error.message,
          'message',
          contains('VISTARA_API_BASE_URL'),
        ),
      ),
    );
  });

  test('invalid API origins are rejected', () {
    expect(
      () => VistaraApi(
        baseUrl: 'https://vistara.example/api',
        sessionStore: _MemorySessionStore(),
      ),
      throwsFormatException,
    );
  });
}

class _MemorySessionStore implements VistaraSessionStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async {
    this.value = value;
  }

  @override
  Future<void> delete() async {
    value = null;
  }
}
