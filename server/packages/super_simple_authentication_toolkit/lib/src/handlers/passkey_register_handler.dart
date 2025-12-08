import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:super_simple_authentication_toolkit/src/webauthn/webauthn_service_client.dart';
import 'package:super_simple_authentication_toolkit/super_simple_authentication_toolkit.dart';

/// Handler for registering a passkey.
Handler passkeyRegisterHandler() {
  return (context) async {
    if (context.request.method != HttpMethod.post) {
      return Response(statusCode: HttpStatus.methodNotAllowed);
    }

    final environment = context.read<Environment>();
    final webauthnServiceUrl = environment['WEBAUTHN_SERVICE_URL'];
    final webauthnServiceApiKey = environment['WEBAUTHN_SERVICE_API_KEY'];
    final rpId = environment['RP_ID'];
    final rpOrigin = environment['RP_ORIGIN'];

    if (webauthnServiceUrl == null || webauthnServiceUrl.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: SignInResponse(error: SignInError.unknown),
      );
    }

    if (rpId == null || rpId.isEmpty || rpOrigin == null || rpOrigin.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: SignInResponse(error: SignInError.unknown),
      );
    }

    try {
      final body = await context.request.json() as Map<String, dynamic>;
      final attestationResponse =
          body['attestationResponse'] as Map<String, dynamic>?;
      final email = body['email'] as String?;

      if (attestationResponse == null) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: SignInResponse(error: SignInError.unknown),
        );
      }

      final client = WebAuthnServiceClient(
        baseUrl: webauthnServiceUrl,
        apiKey: webauthnServiceApiKey,
      );

      final verificationResult = await client.verifyAttestation(
        attestationResponse: attestationResponse,
        rpId: rpId,
        origin: rpOrigin,
      );

      if (!verificationResult.success) {
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          body: SignInResponse(error: SignInError.invalid3rdPartyCredential),
        );
      }

      final dataStorage = context.read<DataStorage>();
      final credentialId = base64Url.decode(verificationResult.credentialId!);

      final publicKey = verificationResult.publicKey;
      if (publicKey == null || publicKey.isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: SignInResponse(error: SignInError.invalid3rdPartyCredential),
        );
      }
      final publicKeyBytes = base64Url.decode(publicKey).toList();

      // Check if credential already exists
      final existingCredential = await dataStorage
          .getPasskeyCredentialByCredentialId(
            credentialId: credentialId,
          );

      if (existingCredential != null) {
        return Response.json(
          statusCode: HttpStatus.conflict,
          body: SignInResponse(error: SignInError.unknown),
        );
      }

      String userId;
      var isNewUser = false;

      // If userHandle is provided, try to find existing user
      final userHandle = verificationResult.userId;
      if (userHandle != null) {
        // Try to find user by userHandle (if stored)
        // For now, we'll create a new user or use email if provided
        if (email != null) {
          final users = await dataStorage.getUsersByEmail(email);
          if (users.isNotEmpty) {
            userId = users.first.id;
          } else {
            userId = await dataStorage.createUser(email: email);
            isNewUser = true;
          }
        } else {
          // Create new user without email (passkey-first signup)
          userId = await dataStorage.createUser();
          isNewUser = true;
        }
      } else {
        // No userHandle, create new user
        if (email != null) {
          final users = await dataStorage.getUsersByEmail(email);
          if (users.isNotEmpty) {
            userId = users.first.id;
          } else {
            userId = await dataStorage.createUser(email: email);
            isNewUser = true;
          }
        } else {
          userId = await dataStorage.createUser();
          isNewUser = true;
        }
      }

      // Store the credential
      await dataStorage.createPasskeyCredential(
        userId: userId,
        credentialId: credentialId,
        publicKey: publicKeyBytes,
        signCount: verificationResult.signCount ?? 0,
        userHandle: userHandle != null
            ? base64Url.decode(userHandle).toList()
            : null,
      );

      // Create session and tokens
      final jwt = await createJwt(
        subject: userId,
        isNewUser: isNewUser,
        environment: environment,
      );
      final refreshToken = createRefreshToken();
      final sessionId = await dataStorage.createSession(userId);
      await dataStorage.createRefreshToken(
        sessionId: sessionId,
        refreshToken: refreshToken,
        userId: userId,
      );

      return Response.json(
        body: SignInResponse(
          token: jwt,
          refreshToken: refreshToken,
        ),
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: SignInResponse(error: SignInError.unknown),
      );
    }
  };
}
