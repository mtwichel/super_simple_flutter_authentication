import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:super_simple_authentication_toolkit/src/webauthn/webauthn_service_client.dart';
import 'package:super_simple_authentication_toolkit/super_simple_authentication_toolkit.dart';

/// Handler for signing in with a passkey.
Handler passkeySignInHandler() {
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
      final assertionResponse =
          body['assertionResponse'] as Map<String, dynamic>?;

      if (assertionResponse == null) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: SignInResponse(error: SignInError.unknown),
        );
      }

      // Extract credential ID from assertion response
      final credentialIdBase64 = assertionResponse['id'] as String?;
      if (credentialIdBase64 == null) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: SignInResponse(error: SignInError.unknown),
        );
      }

      final dataStorage = context.read<DataStorage>();
      final credentialId = base64Url.decode(credentialIdBase64).toList();

      // Get the credential from database
      final credential = await dataStorage.getPasskeyCredentialByCredentialId(
        credentialId: credentialId,
      );

      if (credential == null) {
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          body: SignInResponse(error: SignInError.invalid3rdPartyCredential),
        );
      }

      final client = WebAuthnServiceClient(
        baseUrl: webauthnServiceUrl,
        apiKey: webauthnServiceApiKey,
      );

      // Verify the assertion
      final verificationResult = await client.verifyAssertion(
        assertionResponse: assertionResponse,
        rpId: rpId,
        origin: rpOrigin,
        credentialId: credentialIdBase64,
        publicKey: credential.publicKey,
        expectedSignCount: credential.signCount,
      );

      if (!verificationResult.success) {
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          body: SignInResponse(error: SignInError.invalid3rdPartyCredential),
        );
      }

      // Update sign count
      final newSignCount =
          verificationResult.signCount ?? credential.signCount + 1;
      if (newSignCount <= credential.signCount) {
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          body: SignInResponse(error: SignInError.invalid3rdPartyCredential),
        );
      }

      await dataStorage.updatePasskeySignCount(
        credentialId: credentialId,
        signCount: newSignCount,
      );

      // Create session and tokens
      final jwt = await createJwt(
        subject: credential.userId,
        isNewUser: false,
        environment: environment,
      );
      final refreshToken = createRefreshToken();
      final sessionId = await dataStorage.createSession(credential.userId);
      await dataStorage.createRefreshToken(
        sessionId: sessionId,
        refreshToken: refreshToken,
        userId: credential.userId,
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
