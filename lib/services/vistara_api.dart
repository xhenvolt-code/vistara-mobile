import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/access_product.dart';
import '../models/account_session.dart';
import '../models/movie.dart';

class VistaraApi {
  VistaraApi({
    http.Client? client,
    FlutterSecureStorage? secureStorage,
    VistaraSessionStore? sessionStore,
    String? baseUrl,
  }) : _client = client ?? http.Client(),
       _sessionStore =
           sessionStore ??
           SecureVistaraSessionStore(
             secureStorage ?? const FlutterSecureStorage(),
           ),
       _baseUri = _parseBaseUri(
         baseUrl ?? const String.fromEnvironment('VISTARA_API_BASE_URL'),
       );

  final http.Client _client;
  final VistaraSessionStore _sessionStore;
  final Uri? _baseUri;

  bool get isConfigured => _baseUri != null;

  static Uri? _parseBaseUri(String value) {
    final trimmedValue = value.trim().replaceFirst(RegExp(r'/+$'), '');
    if (trimmedValue.isEmpty) return null;

    final uri = Uri.tryParse(trimmedValue);
    if (uri == null ||
        !uri.hasScheme ||
        !const {'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw const FormatException(
        'VISTARA_API_BASE_URL must be an HTTP(S) origin without a path.',
      );
    }

    return uri;
  }

  Future<List<Movie>> loadCatalogue() async {
    final response = await _request('GET', '/api/mobile/catalogue');
    final movies = response['movies'];
    if (movies is! List) {
      throw const VistaraApiException('The catalogue response is invalid.');
    }

    try {
      return movies
          .map((movie) {
            if (movie is! Map<String, dynamic>) {
              throw const VistaraApiException('A catalogue entry is invalid.');
            }
            return Movie.fromJson(movie);
          })
          .toList(growable: false);
    } on FormatException {
      throw const VistaraApiException(
        'Vistara returned invalid catalogue details. Try again later.',
      );
    }
  }

  Future<List<AccessProduct>> loadAccessProducts() async {
    final response = await _request('GET', '/api/mobile/access-products');
    final products = response['products'];
    if (products is! List) {
      throw const VistaraApiException('The access pass response is invalid.');
    }

    try {
      return products
          .map((product) {
            if (product is! Map<String, dynamic>) {
              throw const VistaraApiException('An access pass is invalid.');
            }
            return AccessProduct.fromJson(product);
          })
          .toList(growable: false);
    } on FormatException {
      throw const VistaraApiException(
        'Vistara returned invalid access pass details. Try again later.',
      );
    }
  }

  Future<AccountSession> restoreSession() async {
    try {
      final response = await _request('GET', '/api/mobile/session');
      return AccountSession.fromJson(response);
    } on VistaraApiException catch (error) {
      if (error.statusCode == 401) await clearSession();
      rethrow;
    } on FormatException {
      throw const VistaraApiException(
        'Vistara returned invalid account details. Sign in again.',
      );
    }
  }

  Future<AccountSession> signIn({
    required String email,
    required String password,
  }) async {
    await _request(
      'POST',
      '/api/auth/sign-in/email',
      body: {'email': email.trim().toLowerCase(), 'password': password},
    );
    return restoreSession();
  }

  Future<AccountSession?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await _request(
      'POST',
      '/api/auth/sign-up/email',
      body: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );

    try {
      return await restoreSession();
    } on VistaraApiException catch (error) {
      if (error.statusCode == 401) return null;
      rethrow;
    }
  }

  Future<void> requestPasswordReset(String email) async {
    final baseUri = _requireBaseUri();
    await _request(
      'POST',
      '/api/auth/request-password-reset',
      body: {
        'email': email.trim().toLowerCase(),
        'redirectTo': baseUri.resolve('/auth/reset-password').toString(),
      },
    );
  }

  Future<void> signOut() async {
    try {
      await _request('POST', '/api/auth/sign-out');
    } finally {
      await clearSession();
    }
  }

  Future<void> clearSession() async {
    await _sessionStore.delete();
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final baseUri = _requireBaseUri();
    final request = http.Request(method, baseUri.resolve(path))
      ..headers['Accept'] = 'application/json'
      ..headers['Origin'] = baseUri.origin;
    final cookieHeader = await _readCookieHeader();
    if (cookieHeader.isNotEmpty) request.headers['Cookie'] = cookieHeader;
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    late final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 20)),
      ).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const VistaraApiException(
        'The Vistara service took too long to respond. Try again.',
      );
    } on http.ClientException {
      throw const VistaraApiException(
        'Unable to reach Vistara. Check your connection and server address.',
      );
    }

    final setCookieHeader = response.headers['set-cookie'];
    await _saveCookies(
      setCookieHeader == null
          ? const []
          : setCookieHeader
                .split(RegExp(r',\s*(?=[^=;,\s]+\s*=)'))
                .toList(growable: false),
    );

    final data = _decodeResponse(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw VistaraApiException(
        _errorMessage(data, response.statusCode),
        statusCode: response.statusCode,
      );
    }

    if (data is! Map<String, dynamic>) {
      throw const VistaraApiException(
        'Vistara returned an unreadable response.',
      );
    }

    return data;
  }

  dynamic _decodeResponse(String body) {
    if (body.isEmpty) return const <String, dynamic>{};
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  String _errorMessage(dynamic data, int statusCode) {
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is String && error.trim().isNotEmpty) return error;
      if (error is Map<String, dynamic> && error['message'] is String) {
        return error['message'] as String;
      }
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) return message;
    }
    return switch (statusCode) {
      401 => 'Your session has expired. Sign in again.',
      403 => 'This account cannot perform that action.',
      404 => 'The requested Vistara resource was not found.',
      >= 500 => 'The Vistara service is temporarily unavailable.',
      _ => 'Vistara could not complete the request ($statusCode).',
    };
  }

  Uri _requireBaseUri() {
    final uri = _baseUri;
    if (uri == null) {
      throw const VistaraApiException(
        'Connect this app to your Vistara server using '
        'VISTARA_API_BASE_URL before signing in.',
      );
    }
    return uri;
  }

  Future<String> _readCookieHeader() async {
    final storedCookies = await _sessionStore.read();
    if (storedCookies == null || storedCookies.isEmpty) return '';

    dynamic decoded;
    try {
      decoded = jsonDecode(storedCookies);
    } on FormatException {
      await clearSession();
      throw const VistaraApiException(
        'The saved sign-in session is invalid. Sign in again.',
      );
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['origin'] != _baseUri?.origin ||
        decoded['cookies'] is! Map<String, dynamic>) {
      await clearSession();
      return '';
    }
    final cookies = decoded['cookies'] as Map<String, dynamic>;
    final now = DateTime.now().millisecondsSinceEpoch;
    return cookies.entries
        .where(
          (entry) =>
              entry.value is Map<String, dynamic> &&
              (entry.value['secure'] != true || _baseUri?.scheme == 'https') &&
              (entry.value['expiresAt'] is! int ||
                  (entry.value['expiresAt'] as int) > now),
        )
        .map(
          (entry) =>
              '${entry.key}=${(entry.value as Map<String, dynamic>)['value']}',
        )
        .join('; ');
  }

  Future<void> _saveCookies(List<String> setCookieHeaders) async {
    if (setCookieHeaders.isEmpty) return;

    final storedCookies = await _sessionStore.read();
    dynamic decoded = <String, dynamic>{};
    if (storedCookies != null && storedCookies.isNotEmpty) {
      try {
        decoded = jsonDecode(storedCookies);
      } on FormatException {
        await clearSession();
        throw const VistaraApiException(
          'The saved sign-in session is invalid. Sign in again.',
        );
      }
    }
    if (decoded is! Map<String, dynamic> ||
        (decoded.isNotEmpty && decoded['origin'] != _baseUri?.origin)) {
      throw const VistaraApiException(
        'Unable to read the saved sign-in session.',
      );
    }
    final cookieData = decoded['cookies'];
    if (decoded.isNotEmpty && cookieData is! Map<String, dynamic>) {
      throw const VistaraApiException(
        'Unable to read the saved sign-in session.',
      );
    }
    final cookies = cookieData is Map<String, dynamic>
        ? Map<String, dynamic>.from(cookieData)
        : <String, dynamic>{};

    for (final header in setCookieHeaders) {
      final parts = header.split(';');
      final cookiePair = parts.first.trim();
      final separator = cookiePair.indexOf('=');
      if (separator <= 0) {
        throw const VistaraApiException(
          'Vistara returned an invalid sign-in cookie.',
        );
      }

      final name = cookiePair.substring(0, separator).trim();
      final value = cookiePair.substring(separator + 1).trim();
      final attributes = Map<String, String>.fromEntries(
        parts.skip(1).map((part) {
          final separator = part.indexOf('=');
          final name = separator < 0
              ? part.trim().toLowerCase()
              : part.substring(0, separator).trim().toLowerCase();
          final value = separator < 0
              ? ''
              : part.substring(separator + 1).trim();
          return MapEntry(name, value);
        }),
      );
      final maxAge = int.tryParse(attributes['max-age'] ?? '');

      if (maxAge != null && maxAge <= 0) {
        cookies.remove(name);
      } else {
        cookies[name] = {
          'value': value,
          'secure': attributes.containsKey('secure'),
          if (maxAge != null)
            'expiresAt': DateTime.now()
                .add(Duration(seconds: maxAge))
                .millisecondsSinceEpoch,
        };
      }
    }

    if (cookies.isEmpty) {
      await clearSession();
    } else {
      await _sessionStore.write(
        jsonEncode({'origin': _baseUri!.origin, 'cookies': cookies}),
      );
    }
  }
}

abstract interface class VistaraSessionStore {
  Future<String?> read();

  Future<void> write(String value);

  Future<void> delete();
}

class SecureVistaraSessionStore implements VistaraSessionStore {
  SecureVistaraSessionStore(this._storage);

  static const _key = 'vistara_auth_cookies';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() async {
    try {
      return await _storage.read(key: _key);
    } on PlatformException {
      throw const VistaraApiException(
        'Unable to access secure sign-in storage on this device.',
      );
    }
  }

  @override
  Future<void> write(String value) async {
    try {
      await _storage.write(key: _key, value: value);
    } on PlatformException {
      throw const VistaraApiException(
        'Unable to securely save the Vistara sign-in session.',
      );
    }
  }

  @override
  Future<void> delete() async {
    try {
      await _storage.delete(key: _key);
    } on PlatformException {
      throw const VistaraApiException(
        'Unable to remove the saved sign-in session from this device.',
      );
    }
  }
}

class VistaraApiException implements Exception {
  const VistaraApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
