import 'package:dart_frog/dart_frog.dart';

/// Middleware that adds CORS headers to the response.
Middleware corsMiddleware({
  String? allowedOrigin,
  List<String>? allowedMethods,
  List<String>? allowedHeaders,
}) {
  return (handler) {
    return (context) async {
      if (context.request.method == HttpMethod.options) {
        final headers = <String, String>{};
        if (allowedOrigin != null) {
          headers['Access-Control-Allow-Origin'] = allowedOrigin;
        }
        if (allowedMethods != null) {
          headers['Access-Control-Allow-Methods'] = allowedMethods.join(',');
        }
        if (allowedHeaders != null) {
          headers['Access-Control-Allow-Headers'] = allowedHeaders.join(',');
        }
        return Response(headers: headers);
      } else {
        final response = await handler(context);
        final headers = <String, String>{...response.headers};
        if (allowedOrigin != null) {
          headers['Access-Control-Allow-Origin'] = allowedOrigin;
        }
        if (allowedMethods != null) {
          headers['Access-Control-Allow-Methods'] = allowedMethods.join(',');
        }
        if (allowedHeaders != null) {
          headers['Access-Control-Allow-Headers'] = allowedHeaders.join(',');
        }
        return response.copyWith(headers: headers);
      }
    };
  };
}
