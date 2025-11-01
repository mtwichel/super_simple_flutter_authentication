import 'package:dart_frog/dart_frog.dart';

/// Middleware that authenticates requests using an API key.
Middleware apiKeyMiddleware({
  required String? apiKey,
}) {
  return (handler) {
    if (apiKey == null) {
      return handler;
    }
    return (context) async {
      final requestApiKey = context.request.headers['x-api-key'];
      if (requestApiKey != apiKey) {
        return Response.json(
          body: {'error': 'API key is required'},
          statusCode: 401,
        );
      }
      if (requestApiKey != apiKey) {
        return Response.json(
          body: {'error': 'invalid API key'},
          statusCode: 401,
        );
      }
      return handler(context);
    };
  };
}
