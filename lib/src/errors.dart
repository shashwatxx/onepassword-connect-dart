/// Typed errors thrown by the Connect client.
library;

/// Base class for every error thrown by this package.
class OnePasswordException implements Exception {
  /// Creates an exception with a human-readable [message].
  const OnePasswordException(this.message);

  /// Human-readable description of what went wrong.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The Connect server responded with an error status code.
class ConnectApiException extends OnePasswordException {
  /// Creates an API exception for [statusCode] with the server's [message].
  const ConnectApiException(this.statusCode, super.message);

  /// Maps an HTTP [statusCode] to the most specific exception type.
  factory ConnectApiException.fromStatus(int statusCode, String message) {
    return switch (statusCode) {
      401 => AuthenticationException(message),
      403 => AuthorizationException(message),
      404 => NotFoundException(message),
      429 => RateLimitException(message),
      >= 500 => ServerException(statusCode, message),
      _ => ConnectApiException(statusCode, message),
    };
  }

  /// HTTP status code returned by the server.
  final int statusCode;

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

/// The access token is missing, malformed, or invalid (HTTP 401).
class AuthenticationException extends ConnectApiException {
  /// Creates a 401 exception.
  const AuthenticationException(String message) : super(401, message);
}

/// The token is valid but not allowed to access the resource (HTTP 403).
class AuthorizationException extends ConnectApiException {
  /// Creates a 403 exception.
  const AuthorizationException(String message) : super(403, message);
}

/// The vault, item, or file does not exist or is not visible (HTTP 404).
class NotFoundException extends ConnectApiException {
  /// Creates a 404 exception.
  const NotFoundException(String message) : super(404, message);
}

/// Too many requests were sent to the Connect server (HTTP 429).
class RateLimitException extends ConnectApiException {
  /// Creates a 429 exception.
  const RateLimitException(String message) : super(429, message);
}

/// The Connect server failed to process the request (HTTP 5xx).
class ServerException extends ConnectApiException {
  /// Creates a 5xx exception.
  const ServerException(super.statusCode, super.message);
}

/// A secret reference URI could not be parsed or resolved.
class SecretReferenceException extends OnePasswordException {
  /// Creates a secret-reference exception.
  const SecretReferenceException(super.message);
}
