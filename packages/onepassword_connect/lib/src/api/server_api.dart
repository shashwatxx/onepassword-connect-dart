import '../http.dart';
import '../models/api_request.dart';

/// Server-level endpoints: health, heartbeat, and the activity log.
class ServerApi {
  /// Creates the API group. Used internally by the client.
  const ServerApi(this._http);

  final ConnectHttpClient _http;

  /// Gets the server's health report (`GET /health`).
  Future<Map<String, dynamic>> health() async =>
      (await _http.getJson('/health')) as Map<String, dynamic>;

  /// Returns true when the server heartbeat responds (`GET /heartbeat`).
  Future<bool> heartbeat() async {
    await _http.getText('/heartbeat');
    return true;
  }

  /// Lists API activity, newest first (`GET /v1/activity`).
  Future<List<ApiRequest>> activity({int? limit, int? offset}) async {
    final json = await _http.getJson('/v1/activity', query: {
      if (limit != null) 'limit': '$limit',
      if (offset != null) 'offset': '$offset',
    });
    return (json as List)
        .map((a) => ApiRequest.fromJson(a as Map<String, dynamic>))
        .toList();
  }
}
