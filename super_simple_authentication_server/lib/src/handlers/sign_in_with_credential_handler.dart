import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:shared_authentication_objects/shared_authentication_objects.dart';
import 'package:super_simple_authentication_server/src/data_storage/data_storage.dart';
import 'package:super_simple_authentication_server/src/integrations/integrations.dart';
import 'package:super_simple_authentication_server/src/util/util.dart';

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

    final environment = context.read<Environment>();

    final String email;
    switch (type) {
      case CredentialType.google:
        try {
          final clientId = environment['GOOGLE_CLIENT_ID'];
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
          final bundleId = environment['APPLE_BUNDLE_ID'];
          final serviceId = environment['APPLE_SERVICE_ID'];

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

    final dataStorage = context.read<DataStorage>();
    final String userId;
    final users = await dataStorage.getUsersByEmail(email);
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

    return Response.json(
      body: SignInWithCredentialResponse(
        token: jwt,
        refreshToken: refreshToken,
      ),
    );
  };
}
