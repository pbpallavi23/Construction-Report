class ApiFailure implements Exception {
  const ApiFailure({
    required this.code,
    required this.message,
    this.statusCode,
  });

  final String code;

  final String message;

  final int? statusCode;

  bool get isUnauthorized => statusCode == 401 || code == 'unauthorized';
  bool get isNetwork => code == 'network' || code == 'timeout';

  @override
  String toString() => 'ApiFailure($code, $statusCode): $message';
}
