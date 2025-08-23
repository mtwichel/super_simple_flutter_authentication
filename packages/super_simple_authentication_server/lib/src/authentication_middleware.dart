import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:super_simple_authentication_server/src/util/user_id.dart';

/// Middleware that authenticates requests using a JWT.
Handler authenticationMiddleware(Handler handler) {
  return (context) async {
    final authorization = context.request.headers['authorization'];

    if (authorization == null) {
      final newContext = context.provide<UserId>(() => null);
      return handler(newContext);
    }
    final userId = _extractUserIdFromAuthorizationHeader(authorization);
    if (userId == null) {
      final newContext = context.provide<UserId>(() => null);
      return handler(newContext);
    }
    final newContext = context.provide<UserId>(() => userId);
    return handler(newContext);
  };
}

/// A helper function to split the authorization header into a token.
String? _extractUserIdFromAuthorizationHeader(String? authorization) {
  if (authorization == null) {
    return null;
  }
  final [_, token] = authorization.split(' ');
  final [_, encodedPayload, _] = token.split('.');
  final decodedPayload = encodedPayload._decode();
  final payload = Map<String, dynamic>.from(jsonDecode(decodedPayload) as Map);
  final subject = payload['sub'];
  if (subject is! String) {
    return null;
  }
  return subject;
}

extension on String {
  String _decode() {
    final buffer = StringBuffer(this);
    while (buffer.length % 4 != 0) {
      buffer.write('=');
    }
    return utf8.decode(base64Url.decode(buffer.toString()));
  }
}
