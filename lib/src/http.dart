import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'errors.dart';

/// Thin HTTP wrapper around the Connect server: adds the bearer token,
/// resolves paths against the base URL, and maps error responses to
/// typed exceptions.
class ConnectHttpClient {
  /// Creates a client for the Connect server at [baseUrl] using [token].
  ///
  /// An [inner] client can be injected for testing or custom transports;
  /// when omitted a default [http.Client] is created and owned by this
  /// instance.
  ConnectHttpClient({
    required Uri baseUrl,
    required String token,
    http.Client? inner,
  })  : _baseUrl = baseUrl,
        _token = token,
        _inner = inner ?? http.Client(),
        _ownsInner = inner == null;

  final Uri _baseUrl;
  final String _token;
  final http.Client _inner;
  final bool _ownsInner;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      };

  /// Resolves [path] (e.g. `/v1/vaults`) against the base URL, preserving
  /// any path prefix on the base URL (reverse-proxy setups).
  Uri resolve(String path, [Map<String, String>? query]) {
    final basePath = _baseUrl.path.endsWith('/')
        ? _baseUrl.path.substring(0, _baseUrl.path.length - 1)
        : _baseUrl.path;
    return _baseUrl.replace(
      path: '$basePath$path',
      queryParameters: (query?.isNotEmpty ?? false) ? query : null,
    );
  }

  /// GET [path] and decode the JSON response.
  Future<Object?> getJson(String path, {Map<String, String>? query}) async {
    final response = await _inner.get(resolve(path, query), headers: _headers);
    return _decode(response);
  }

  /// GET [path] and return the raw response bytes (file downloads).
  Future<Uint8List> getBytes(String path) async {
    final response = await _inner.get(resolve(path), headers: _headers);
    _throwIfError(response.statusCode, () => response.body);
    return response.bodyBytes;
  }

  /// GET [path] and return the response body as text (heartbeat/metrics).
  Future<String> getText(String path) async {
    final response = await _inner.get(resolve(path), headers: _headers);
    _throwIfError(response.statusCode, () => response.body);
    return response.body;
  }

  /// POST [body] as JSON to [path] and decode the JSON response.
  Future<Object?> postJson(String path, Object body) async {
    final response = await _inner.post(resolve(path),
        headers: _headers, body: jsonEncode(body));
    return _decode(response);
  }

  /// PUT [body] as JSON to [path] and decode the JSON response.
  Future<Object?> putJson(String path, Object body) async {
    final response = await _inner.put(resolve(path),
        headers: _headers, body: jsonEncode(body));
    return _decode(response);
  }

  /// PATCH [body] (RFC 6902 JSON Patch) to [path] and decode the response.
  Future<Object?> patchJson(String path, Object body) async {
    final response = await _inner.patch(resolve(path),
        headers: _headers, body: jsonEncode(body));
    return _decode(response);
  }

  /// DELETE [path]; the API returns 204 No Content on success.
  Future<void> delete(String path) async {
    final response = await _inner.delete(resolve(path), headers: _headers);
    _throwIfError(response.statusCode, () => response.body);
  }

  /// Releases the underlying HTTP client if this instance created it.
  void close() {
    if (_ownsInner) _inner.close();
  }

  Object? _decode(http.Response response) {
    _throwIfError(response.statusCode, () => response.body);
    if (response.body.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  void _throwIfError(int statusCode, String Function() body) {
    if (statusCode < 400) return;
    var message = 'HTTP $statusCode';
    try {
      final decoded = jsonDecode(body());
      if (decoded is Map<String, dynamic> && decoded['message'] is String) {
        message = decoded['message'] as String;
      }
    } on FormatException {
      // Non-JSON error body; keep the generic message.
    }
    throw ConnectApiException.fromStatus(statusCode, message);
  }
}
