import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:super_simple_authentication_toolkit/super_simple_authentication_toolkit.dart';

/// [Handler] for signing in with a 3rd party credential.
Handler signInWithCredentialHandler() {
  return (context) async {
    if (context.request.method != HttpMethod.post) {
      return Response(statusCode: HttpStatus.methodNotAllowed);
    }

    final {'credential': String credential, 'type': String type} = await context
        .request
        .map();

    final parts = credential.split('.');
    if (parts.length != 3) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Invalid 3rd party credential'},
      );
    }

    final environment = context.read<Environment>();

    final String email;
    switch (type) {
      case 'google':
        try {
          final clientId = environment['GOOGLE_CLIENT_ID'];
          if (clientId == null || clientId.isEmpty) {
            return Response.json(
              statusCode: HttpStatus.internalServerError,
              body: {'error': 'Server error'},
            );
          }
          final googleVerifier = SignInWithGoogle(clientId: clientId);
          final extractedEmail = await googleVerifier.verifyToken(credential);
          if (extractedEmail.isEmpty) {
            return Response.json(
              statusCode: HttpStatus.unauthorized,
              body: {'error': 'Invalid 3rd party credential'},
            );
          }
          email = extractedEmail;
        } catch (_) {
          return Response.json(
            statusCode: HttpStatus.unauthorized,
            body: {'error': 'Invalid 3rd party credential'},
          );
        }
      case 'apple':
        try {
          final bundleId = environment['APPLE_BUNDLE_ID'];
          final serviceId = environment['APPLE_SERVICE_ID'];

          if (bundleId == null || bundleId.isEmpty) {
            return Response.json(
              statusCode: HttpStatus.internalServerError,
              body: {'error': 'Server error'},
            );
          }

          final appleVerifier = SignInWithApple(
            bundleId: bundleId,
            serviceId: serviceId,
          );
          final extractedEmail = await appleVerifier.verifyToken(credential);
          if (extractedEmail.isEmpty) {
            return Response.json(
              statusCode: HttpStatus.unauthorized,
              body: {'error': 'Invalid 3rd party credential'},
            );
          }
          email = extractedEmail;
        } catch (_) {
          return Response.json(
            statusCode: HttpStatus.unauthorized,
            body: {'error': 'Invalid 3rd party credential'},
          );
        }
      default:
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          body: {'error': 'Invalid 3rd party credential'},
        );
    }

    final dataStorage = context.read<DataStorage>();
    final String userId;
    final users = await dataStorage.getUsersByEmail(email);
    if (users.length > 1) {
      return Response.json(body: {'error': 'Unknown error'});
    }
    final isNewUser = users.isEmpty;
    if (users.isEmpty) {
      userId = await dataStorage.createUser(email: email);
    } else {
      userId = users.first.id;
    }

    final jwt = await createJwt(
      subject: userId,
      isNewUser: isNewUser,
      environment: context.read<Environment>(),
    );

    final refreshToken = createRefreshToken();

    final sessionId = await dataStorage.createSession(userId);
    await dataStorage.createRefreshToken(
      sessionId: sessionId,
      refreshToken: refreshToken,
      userId: userId,
    );

    return Response.json(body: {'token': jwt, 'refreshToken': refreshToken});
  };
}
