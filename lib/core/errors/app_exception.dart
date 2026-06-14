class AppException implements Exception {
  AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class PdfExtractionException extends AppException {
  PdfExtractionException(super.message, {super.cause});
}

class LeaseExtractionException extends AppException {
  LeaseExtractionException(super.message, {super.cause});
}

class AppStorageException extends AppException {
  AppStorageException(super.message, {super.cause});
}

class RepositoryException extends AppException {
  RepositoryException(super.message, {super.cause});
}
