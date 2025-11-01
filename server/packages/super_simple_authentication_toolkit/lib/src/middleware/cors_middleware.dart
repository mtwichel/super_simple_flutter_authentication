import 'package:dart_frog/dart_frog.dart';

/// Middleware that adds CORS headers to the response.
Middleware corsMiddleware({
  String? allowedOrigin,
  List<String>? allowedMethods,
  List<String>? allowedHeaders,
}) {
  return (handler) {
    return (context) async {
      final response = await handler(context);
      if (allowedOrigin != null) {
        response.headers['Access-Control-Allow-Origin'] = allowedOrigin;
      }
      if (allowedMethods != null) {
        response.headers['Access-Control-Allow-Methods'] = allowedMethods.join(
          ',',
        );
      }
      if (allowedHeaders != null) {
        response.headers['Access-Control-Allow-Headers'] = allowedHeaders.join(
          ',',
        );
      }
      return response;
    };
  };
}
