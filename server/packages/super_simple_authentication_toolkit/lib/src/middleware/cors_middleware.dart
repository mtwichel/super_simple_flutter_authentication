import 'package:dart_frog/dart_frog.dart';

/// Middleware that adds CORS headers to the response.
Middleware corsMiddleware() {
  return (handler) {
    return (context) async {
      final response = await handler(context);
      response.headers['Access-Control-Allow-Origin'] = '*';
      response.headers['Access-Control-Allow-Methods'] =
          'GET, POST, PUT, DELETE, OPTIONS';
      response.headers['Access-Control-Allow-Headers'] =
          'Content-Type, Authorization';
      return response;
    };
  };
}
