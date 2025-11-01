import 'package:dart_frog/dart_frog.dart';
import 'package:super_simple_authentication_toolkit/super_simple_authentication_toolkit.dart';

/// Middleware that authenticates requests using a JWT.
Middleware authenticationMiddleware() {
  return (handler) {
    return (context) async {
      final authorization = context.request.headers['authorization'];

      if (authorization == null) {
        final newContext = context.provide<UserId>(() => null);
        return handler(newContext);
      }
      final jwt = await verifyJwt(authorization);
      if (jwt == null) {
        final newContext = context.provide<UserId>(() => null);
        return handler(newContext);
      }
      final userId = jwt['sub'] as String?;
      if (userId == null) {
        final newContext = context.provide<UserId>(() => null);
        return handler(newContext);
      }
      final newContext = context.provide<UserId>(() => userId);
      return handler(newContext);
    };
  };
}
