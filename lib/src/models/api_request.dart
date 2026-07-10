import 'package:meta/meta.dart';

/// An entry from the Connect server's activity log (`GET /v1/activity`).
@immutable
class ApiRequest {
  /// Creates an activity entry.
  const ApiRequest({
    this.requestId,
    this.timestamp,
    this.action,
    this.result,
    this.actor,
    this.resource,
  });

  /// Decodes an activity entry from JSON.
  factory ApiRequest.fromJson(Map<String, dynamic> json) => ApiRequest(
        requestId: json['requestId'] as String?,
        timestamp: json['timestamp'] is String
            ? DateTime.tryParse(json['timestamp'] as String)
            : null,
        action: json['action'] as String?,
        result: json['result'] as String?,
        actor: json['actor'] == null
            ? null
            : ApiRequestActor.fromJson(json['actor'] as Map<String, dynamic>),
        resource: json['resource'] == null
            ? null
            : ApiRequestResource.fromJson(
                json['resource'] as Map<String, dynamic>),
      );

  /// Unique request identifier.
  final String? requestId;

  /// When the request was made.
  final DateTime? timestamp;

  /// `READ`, `CREATE`, `UPDATE`, or `DELETE`.
  final String? action;

  /// `SUCCESS` or `DENY`.
  final String? result;

  /// Who made the request.
  final ApiRequestActor? actor;

  /// What the request touched.
  final ApiRequestResource? resource;
}

/// The token/requester behind an [ApiRequest].
@immutable
class ApiRequestActor {
  /// Creates an actor.
  const ApiRequestActor({
    this.id,
    this.account,
    this.jti,
    this.userAgent,
    this.requestIp,
  });

  /// Decodes an actor from JSON.
  factory ApiRequestActor.fromJson(Map<String, dynamic> json) =>
      ApiRequestActor(
        id: json['id'] as String?,
        account: json['account'] as String?,
        jti: json['jti'] as String?,
        userAgent: json['userAgent'] as String?,
        requestIp: json['requestIp'] as String?,
      );

  /// Access token identifier.
  final String? id;

  /// 1Password account identifier.
  final String? account;

  /// JWT token ID.
  final String? jti;

  /// User agent of the requester.
  final String? userAgent;

  /// IP address the request came from.
  final String? requestIp;
}

/// The resource an [ApiRequest] accessed.
@immutable
class ApiRequestResource {
  /// Creates a resource.
  const ApiRequestResource(
      {this.type, this.vaultId, this.itemId, this.itemVersion});

  /// Decodes a resource from JSON.
  factory ApiRequestResource.fromJson(Map<String, dynamic> json) =>
      ApiRequestResource(
        type: json['type'] as String?,
        vaultId: (json['vault'] as Map<String, dynamic>?)?['id'] as String?,
        itemId: (json['item'] as Map<String, dynamic>?)?['id'] as String?,
        itemVersion: json['itemVersion'] as int?,
      );

  /// `ITEM` or `VAULT`.
  final String? type;

  /// Vault the request touched.
  final String? vaultId;

  /// Item the request touched.
  final String? itemId;

  /// Version of the accessed item.
  final int? itemVersion;
}
