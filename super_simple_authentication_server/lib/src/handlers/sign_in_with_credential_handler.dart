import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_utilities/dart_frog_utilities.dart';
import 'package:postgres_builder/postgres_builder.dart';
import 'package:shared_authentication_objects/shared_authentication_objects.dart';
import 'package:super_simple_authentication_server/src/create_jwt.dart';
import 'package:super_simple_authentication_server/src/create_refresh_token.dart';
import 'package:super_simple_authentication_server/src/integrations/integrations.dart';

/// [Handler] for signing in with a 3rd party credential.
Handler signInWithCredentialHandler() {
  return (context) async {
    if (context.request.method != HttpMethod.post) {
      return Response(statusCode: HttpStatus.methodNotAllowed);
    }

    final SignInWithCredentialRequest(
      credential: Credential(type: type, token: token),
    ) = await context.request.parse(SignInWithCredentialRequest.fromJson);

    final parts = token.split('.');
    if (parts.length != 3) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: const VerifyOtpResponse(
          token: null,
          error: SignInError.invalid3rdPartyCredential,
          refreshToken: null,
        ),
      );
    }

    final String email;
    switch (type) {
      case CredentialType.google:
        try {
          final clientId = context.environment['GOOGLE_CLIENT_ID'];
          if (clientId == null || clientId.isEmpty) {
            return Response.json(
              statusCode: HttpStatus.internalServerError,
              body: const VerifyOtpResponse(
                token: null,
                error: SignInError.serverError,
                refreshToken: null,
              ),
            );
          }
          final googleVerifier = SignInWithGoogle(clientId: clientId);
          final extractedEmail = await googleVerifier.verifyToken(token);
          if (extractedEmail.isEmpty) {
            return Response.json(
              statusCode: HttpStatus.unauthorized,
              body: const VerifyOtpResponse(
                token: null,
                error: SignInError.invalid3rdPartyCredential,
                refreshToken: null,
              ),
            );
          }
          email = extractedEmail;
        } catch (_) {
          return Response.json(
            statusCode: HttpStatus.unauthorized,
            body: const VerifyOtpResponse(
              token: null,
              error: SignInError.invalid3rdPartyCredential,
              refreshToken: null,
            ),
          );
        }
      case CredentialType.apple:
        try {
          final bundleId = context.environment['APPLE_BUNDLE_ID'];
          final serviceId = context.environment['APPLE_SERVICE_ID'];

          if (bundleId == null || bundleId.isEmpty) {
            return Response.json(
              statusCode: HttpStatus.internalServerError,
              body: const VerifyOtpResponse(
                token: null,
                error: SignInError.serverError,
                refreshToken: null,
              ),
            );
          }

          final appleVerifier = SignInWithApple(
            bundleId: bundleId,
            serviceId: serviceId,
          );
          final extractedEmail = await appleVerifier.verifyToken(token);
          if (extractedEmail.isEmpty) {
            return Response.json(
              statusCode: HttpStatus.unauthorized,
              body: const VerifyOtpResponse(
                token: null,
                error: SignInError.invalid3rdPartyCredential,
                refreshToken: null,
              ),
            );
          }
          email = extractedEmail;
        } catch (_) {
          return Response.json(
            statusCode: HttpStatus.unauthorized,
            body: const VerifyOtpResponse(
              token: null,
              error: SignInError.invalid3rdPartyCredential,
              refreshToken: null,
            ),
          );
        }
    }

    final database = context.read<PostgresBuilder>();

    final String userId;
    final users = await database.mappedQuery(
      Select(
        [const Column('id')],
        from: 'users',
        where: const Column('email').equals(email),
      ),
      fromJson: (row) => row['id'] as String,
    );
    if (users.length > 1) {
      return Response.json(
        body: const VerifyOtpResponse(
          token: null,
          error: SignInError.unknown,
          refreshToken: null,
        ),
      );
    }
    final isNewUser = users.isEmpty;
    if (users.isEmpty) {
      userId = await database.mappedSingleQuery(
        Insert([
          {'email': email},
        ], into: 'users'),
        fromJson: (row) => row['id'] as String,
      );
    } else {
      userId = users.first;
    }

    final jwt = await createJwt(subject: userId, isNewUser: isNewUser);

    final refreshToken = createRefreshToken();

    final sessionId = await database.mappedSingleQuery(
      Insert([
        {'user_id': userId},
      ], into: 'auth.sessions'),
      fromJson: (row) => row['id'] as String,
    );
    await database.execute(
      Insert([
        {'user_id': userId, 'token': refreshToken, 'session_id': sessionId},
      ], into: 'auth.refresh_tokens'),
    );

    return Response.json(
      body: SignInWithCredentialResponse(
        token: jwt,
        refreshToken: refreshToken,
      ),
    );
  };
}
