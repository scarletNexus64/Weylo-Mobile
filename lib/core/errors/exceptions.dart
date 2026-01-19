class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  AppException({required this.message, this.statusCode, this.data});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException({String message = 'Erreur de connexion réseau'})
    : super(message: message);
}

class ServerException extends AppException {
  ServerException({
    String message = 'Erreur serveur',
    int? statusCode,
    dynamic data,
  }) : super(message: message, statusCode: statusCode, data: data);
}

class AuthException extends AppException {
  AuthException({String message = 'Erreur d\'authentification'})
    : super(message: message, statusCode: 401);
}

class ValidationException extends AppException {
  final Map<String, dynamic>? errors;

  ValidationException({String message = 'Erreur de validation', this.errors})
    : super(message: message, statusCode: 422);
}

class NotFoundException extends AppException {
  NotFoundException({String message = 'Ressource non trouvée'})
    : super(message: message, statusCode: 404);
}

class ForbiddenException extends AppException {
  ForbiddenException({String message = 'Accès refusé'})
    : super(message: message, statusCode: 403);
}

class RateLimitException extends AppException {
  RateLimitException({String message = 'Trop de requêtes, veuillez patienter'})
    : super(message: message, statusCode: 429);
}

class MaintenanceException extends AppException {
  MaintenanceException({String message = 'Application en maintenance'})
    : super(message: message, statusCode: 503);
}
