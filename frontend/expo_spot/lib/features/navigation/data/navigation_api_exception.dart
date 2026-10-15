class NavigationApiException implements Exception {
  NavigationApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
