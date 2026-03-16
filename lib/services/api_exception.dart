// lib/services/api_exception.dart

/// Base class for all API-related exceptions
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

/// Thrown when there is no internet connection or the server is unreachable
class NetworkException extends ApiException {
  const NetworkException(super.message);

  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown when the server returns a 4xx or 5xx status code
class ServerException extends ApiException {
  const ServerException(super.message, {super.statusCode});

  @override
  String toString() => 'ServerException: $message (status: $statusCode)';
}

/// Thrown when JSON parsing fails
class ParseException extends ApiException {
  const ParseException(super.message);

  @override
  String toString() => 'ParseException: $message';
}

/// Thrown when a requested resource is not found (404)
class NotFoundException extends ApiException {
  const NotFoundException(super.message) : super(statusCode: 404);

  @override
  String toString() => 'NotFoundException: $message';
}
