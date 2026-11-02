import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vistara_mobile/models/access_product.dart';
import 'package:vistara_mobile/services/vistara_api.dart';

void main() {
  test('defaults to the deployed Vistara API origin', () async {
    final api = VistaraApi(
      sessionStore: _MemorySessionStore(),
      client: MockClient((request) async {
        expect(request.url.origin, 'https://vistara-main.vercel.app');
        expect(request.url.path, '/api/mobile/catalogue');
        return http.Response(jsonEncode({'movies': []}), 200);
      }),
    );

    expect(api.isConfigured, isTrue);
    expect(await api.loadCatalogue(), isEmpty);
  });

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
                'director': 'A. Director',
                'cast': ['Actor One', 'Actor Two'],
                'contentRating': 'PG-13',
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
    expect(movies.single.director, 'A. Director');
    expect(movies.single.cast, ['Actor One', 'Actor Two']);
    expect(movies.single.contentRating, 'PG-13');
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
    expect(products.single.termLabel, 'Weekly');
  });

  test(
    'subscription payment uses authenticated MarzPay collection endpoint',
    () async {
      final store = _MemorySessionStore()
        ..value = jsonEncode({
          'origin': 'https://vistara.example',
          'cookies': {
            'vistara.session': {'value': 'opaque-session', 'secure': true},
          },
        });
      final api = VistaraApi(
        baseUrl: 'https://vistara.example',
        sessionStore: store,
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/payments/marzpay/collections');
          expect(request.headers['origin'], 'https://vistara.example');
          expect(request.headers['cookie'], 'vistara.session=opaque-session');
          expect(request.headers['content-type'], 'application/json');
          expect(
            request.headers['idempotency-key'],
            matches(
              RegExp(
                r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
                r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
              ),
            ),
          );
          expect(jsonDecode(request.body), {
            'productId': 'weekly-plan',
            'phoneNumber': '+256700000000',
          });
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

      final purchase = await api.createSubscriptionPurchase(
        productId: 'weekly-plan',
        phoneNumber: ' +256700000000 ',
      );

      expect(purchase.purchaseId, 'purchase-1');
      expect(purchase.status, 'PENDING');
      expect(purchase.message, 'Payment prompt requested.');
    },
  );

  test(
    'playback URL and headers use the protected, authenticated endpoint',
    () async {
      final store = _MemorySessionStore()
        ..value = jsonEncode({
          'origin': 'https://vistara.example',
          'cookies': {
            'vistara.session': {'value': 'opaque-token', 'secure': true},
          },
        });
      final api = VistaraApi(
        baseUrl: 'https://vistara.example',
        sessionStore: store,
      );

      expect(
        api.playbackUri('night-road'),
        Uri.parse('https://vistara.example/api/movies/night-road/playback'),
      );
      expect(await api.playbackHeaders(), {
        'Accept': 'video/mp4',
        'Cookie': 'vistara.session=opaque-token',
      });
    },
  );

  test('playback requires an authenticated session cookie', () async {
    final api = VistaraApi(
      baseUrl: 'https://vistara.example',
      sessionStore: _MemorySessionStore(),
    );

    await expectLater(
      api.playbackHeaders(),
      throwsA(
        isA<VistaraApiException>()
            .having((error) => error.statusCode, 'status code', 401)
            .having(
              (error) => error.message,
              'message',
              'Sign in to watch this title.',
            ),
      ),
    );
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

  test(
    'Google sign-in follows the Neon browser flow and exchanges its handoff',
    () async {
      final store = _MemorySessionStore();
      var sessionRequestCount = 0;
      String? state;
      String? codeChallenge;
      final ticket = List<String>.filled(43, 'A').join();
      final api = VistaraApi(
        baseUrl: 'https://vistara.example',
        sessionStore: store,
        client: MockClient((request) async {
          if (request.url.path == '/api/auth/sign-in/social') {
            expect(request.headers['origin'], 'https://vistara.example');
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['provider'], 'google');
            expect(body['disableRedirect'], isTrue);
            final callbackUri = Uri.parse(body['callbackURL'] as String);
            expect(callbackUri.origin, 'https://vistara.example');
            expect(callbackUri.path, '/auth/mobile/callback');
            state = callbackUri.queryParameters['state'];
            codeChallenge = callbackUri.queryParameters['code_challenge'];
            expect(state, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
            expect(codeChallenge, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
            return http.Response(
              jsonEncode({
                'url': 'https://neon.example/auth/sign-in/social/init',
                'redirect': false,
              }),
              200,
            );
          }

          if (request.url.path == '/api/mobile/auth/exchange') {
            expect(request.headers['origin'], 'https://vistara.example');
            expect(jsonDecode(request.body), {
              'ticket': ticket,
              'state': state,
              'verifier': store.pendingGoogleAuthVerifier,
            });
            return http.Response(
              jsonEncode({'authenticated': true}),
              200,
              headers: {
                'set-cookie':
                    '__Secure-neon-auth.session_token=opaque-token; Path=/; '
                    'HttpOnly; Secure; SameSite=Lax',
              },
            );
          }

          expect(request.url.path, '/api/mobile/session');
          expect(
            request.headers['cookie'],
            '__Secure-neon-auth.session_token=opaque-token',
          );
          sessionRequestCount++;
          return http.Response(
            jsonEncode({
              'user': {
                'id': 'google-user',
                'email': 'viewer@example.com',
                'name': 'Vistara Viewer',
                'accountStatus': 'ACTIVE',
              },
              'entitlement': null,
              'purchases': [],
            }),
            200,
          );
        }),
      );

      final authUri = await api.startGoogleSignIn();
      expect(authUri.host, 'neon.example');
      expect(store.pendingGoogleAuthState, state);
      expect(
        codeChallenge,
        base64UrlEncode(
          sha256.convert(utf8.encode(store.pendingGoogleAuthVerifier!)).bytes,
        ).replaceAll('=', ''),
      );

      final session = await api.completeGoogleSignIn(
        Uri(
          scheme: 'vistara',
          host: 'auth',
          path: '/callback',
          queryParameters: {'ticket': ticket, 'state': state},
        ),
      );

      expect(session.user.id, 'google-user');
      expect(sessionRequestCount, 1);
      expect(store.value, contains('opaque-token'));
      expect(store.pendingGoogleAuthState, isNull);
    },
  );

  test('Google sign-in rejects an invalid callback state', () async {
    final store = _MemorySessionStore();
    final api = VistaraApi(
      baseUrl: 'https://vistara.example',
      sessionStore: store,
    );

    await expectLater(
      api.completeGoogleSignIn(
        Uri(
          scheme: 'vistara',
          host: 'auth',
          path: '/callback',
          queryParameters: {
            'ticket': 'one-time-handoff-ticket-0000000000000000000000000',
            'state': 'unrecognized-state',
          },
        ),
      ),
      throwsA(
        isA<VistaraApiException>().having(
          (error) => error.message,
          'message',
          'This Google sign-in attempt is no longer active. Start again.',
        ),
      ),
    );
  });

  test('Google sign-in rejects an unsafe authorization URL', () async {
    final store = _MemorySessionStore();
    final api = VistaraApi(
      baseUrl: 'https://vistara.example',
      sessionStore: store,
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'url': 'javascript:alert(1)', 'redirect': false}),
          200,
        ),
      ),
    );

    await expectLater(
      api.startGoogleSignIn(),
      throwsA(
        isA<VistaraApiException>().having(
          (error) => error.message,
          'message',
          'Vistara returned an invalid Google sign-in address.',
        ),
      ),
    );
    expect(store.pendingGoogleAuthState, isNull);
  });

  test('Google OAuth cancellation clears its pending state', () async {
    final store = _MemorySessionStore();
    final api = VistaraApi(
      baseUrl: 'https://vistara.example',
      sessionStore: store,
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'url': 'https://neon.example/auth/sign-in/social/init',
            'redirect': false,
          }),
          200,
        ),
      ),
    );

    await api.startGoogleSignIn();
    final state = store.pendingGoogleAuthState!;

    await expectLater(
      api.completeGoogleSignIn(
        Uri(
          scheme: 'vistara',
          host: 'auth',
          path: '/callback',
          queryParameters: {'state': state, 'error': 'google_sign_in_failed'},
        ),
      ),
      throwsA(isA<VistaraApiException>()),
    );
    expect(store.pendingGoogleAuthState, isNull);
  });

  test('Google sign-in rejects a native redirect response', () async {
    final store = _MemorySessionStore();
    final api = VistaraApi(
      baseUrl: 'https://vistara.example',
      sessionStore: store,
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'url': 'https://neon.example/auth/sign-in/social/init',
            'redirect': true,
          }),
          200,
        ),
      ),
    );

    await expectLater(
      api.startGoogleSignIn(),
      throwsA(isA<VistaraApiException>()),
    );
    expect(store.pendingGoogleAuthState, isNull);
  });

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

  test('expired Set-Cookie attributes revoke the saved session', () async {
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
        (_) async => http.Response(
          jsonEncode({'products': []}),
          200,
          headers: {
            'set-cookie': 'vistara.session=; Path=/; Expires=Wed, 21 Oct 2015 07:28:00 GMT; Secure',
          },
        ),
      ),
    );

    await api.loadAccessProducts();

    expect(store.value, isNull);
  });

  test('unconfigured API fails with setup guidance, not fake data', () async {
    final api = VistaraApi(baseUrl: '', sessionStore: _MemorySessionStore());

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
  String? pendingGoogleAuthState;
  String? pendingGoogleAuthVerifier;

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

  @override
  Future<String?> readGoogleAuthState() async => pendingGoogleAuthState;

  @override
  Future<String?> readGoogleAuthVerifier() async => pendingGoogleAuthVerifier;

  @override
  Future<void> writeGoogleAuthAttempt(String state, String verifier) async {
    pendingGoogleAuthState = state;
    pendingGoogleAuthVerifier = verifier;
  }

  @override
  Future<void> deleteGoogleAuthAttempt() async {
    pendingGoogleAuthState = null;
    pendingGoogleAuthVerifier = null;
  }
}
