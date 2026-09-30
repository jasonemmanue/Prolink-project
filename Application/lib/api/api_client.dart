import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Erreur renvoyée par l'API (message lisible en français).
class ApiException implements Exception {
  final int status;
  final String message;
  final Map<String, dynamic>? body;
  ApiException(this.status, this.message, [this.body]);
  @override
  String toString() => message;
}

/// Client HTTP de l'API ProLink (FastAPI).
///
/// - URL du serveur : `--dart-define=API_URL=...` au build, modifiable dans
///   l'app (écran de connexion → Serveur) et mémorisée.
/// - JWT d'accès + rafraîchissement automatique sur 401.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const String defaultUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:8000', // émulateur Android → PC hôte
  );

  static const _kUrl = 'api_url';
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';

  String baseUrl = defaultUrl;
  String? _access;
  String? _refresh;
  final _http = http.Client();

  bool get hasSession => _access != null;
  String? get accessToken => _access;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    baseUrl = p.getString(_kUrl) ?? defaultUrl;
    _access = p.getString(_kAccess);
    _refresh = p.getString(_kRefresh);
  }

  Future<void> setBaseUrl(String url) async {
    baseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    final p = await SharedPreferences.getInstance();
    await p.setString(_kUrl, baseUrl);
  }

  Future<void> saveTokens(String access, String refresh) async {
    _access = access;
    _refresh = refresh;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAccess, access);
    await p.setString(_kRefresh, refresh);
  }

  Future<void> clearTokens() async {
    _access = null;
    _refresh = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(_kAccess);
    await p.remove(_kRefresh);
  }

  /// Vérifie que le serveur répond (écran de connexion / réglage serveur).
  Future<bool> ping() async {
    try {
      final r = await _http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 4));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = query?.map((k, v) => MapEntry(k, '$v'))
      ?..removeWhere((k, v) => v == 'null');
    return Uri.parse('$baseUrl/api/v1$path').replace(queryParameters: q);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send('GET', path, query: query);
  Future<dynamic> post(String path, [Object? body, Map<String, dynamic>? query]) =>
      _send('POST', path, body: body, query: query);
  Future<dynamic> patch(String path, [Object? body]) =>
      _send('PATCH', path, body: body);
  Future<dynamic> put(String path, [Object? body]) =>
      _send('PUT', path, body: body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool retried = false,
  }) async {
    final req = http.Request(method, _uri(path, query));
    req.headers['Accept'] = 'application/json';
    if (_access != null) req.headers['Authorization'] = 'Bearer $_access';
    if (body != null) {
      req.headers['Content-Type'] = 'application/json';
      req.body = jsonEncode(body);
    }
    http.Response res;
    try {
      res = await http.Response.fromStream(
        await _http.send(req).timeout(const Duration(seconds: 15)),
      );
    } on TimeoutException {
      throw ApiException(0, 'Le serveur ne répond pas ($baseUrl)');
    } catch (_) {
      throw ApiException(0, 'Connexion impossible au serveur ($baseUrl)');
    }

    if (res.statusCode == 401 && !retried && _refresh != null &&
        !path.startsWith('/auth/login')) {
      if (await _tryRefresh()) {
        return _send(method, path, body: body, query: query, retried: true);
      }
    }
    final text = utf8.decode(res.bodyBytes);
    final data = text.isEmpty ? null : _tryJson(text);
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    throw ApiException(res.statusCode, _message(data, res.statusCode),
        data is Map<String, dynamic> ? data : null);
  }

  Future<bool> _tryRefresh() async {
    try {
      final r = await _http.post(
        _uri('/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': _refresh}),
      );
      if (r.statusCode != 200) return false;
      final d = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      await saveTokens(d['access_token'], d['refresh_token']);
      return true;
    } catch (_) {
      return false;
    }
  }

  static dynamic _tryJson(String s) {
    try {
      return jsonDecode(s);
    } catch (_) {
      return s;
    }
  }

  static String _message(dynamic data, int status) {
    if (data is Map && data['detail'] != null) {
      final d = data['detail'];
      if (d is String) return d;
      if (d is List && d.isNotEmpty && d.first is Map) {
        final first = d.first as Map;
        final field = (first['loc'] as List?)?.last;
        return '${field ?? 'Champ'} : ${first['msg']}';
      }
    }
    return switch (status) {
      401 => 'Session expirée, reconnectez-vous',
      403 => 'Action non autorisée',
      404 => 'Élément introuvable',
      _ => 'Erreur serveur ($status)',
    };
  }
}
