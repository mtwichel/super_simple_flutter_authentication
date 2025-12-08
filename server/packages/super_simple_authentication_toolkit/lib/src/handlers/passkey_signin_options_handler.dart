import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:super_simple_authentication_toolkit/super_simple_authentication_toolkit.dart';
import 'package:super_simple_authentication_toolkit/src/webauthn/webauthn_service_client.dart';

/// Handler for getting passkey sign-in options.
Handler passkeySignInOptionsHandler() {
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
        body: {'error': 'WEBAUTHN_SERVICE_URL is not configured'},
      );
    }

    if (rpId == null || rpId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'error': 'RP_ID is not configured'},
      );
    }

    if (rpOrigin == null || rpOrigin.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'error': 'RP_ORIGIN is not configured'},
      );
    }

    try {
      final body = await context.request.json() as Map<String, dynamic>?;
      final email = body?['email'] as String?;

      final dataStorage = context.read<DataStorage>();
      List<String>? allowCredentials;

      // If email is provided, get credentials for that user
      if (email != null) {
        final users = await dataStorage.getUsersByEmail(email);
        if (users.isNotEmpty) {
          final credentials = await dataStorage.getPasskeyCredentialsByUserId(
            userId: users.first.id,
          );
          allowCredentials = credentials
              .map((c) => base64Url.encode(c.credentialId))
              .toList();
        }
      }

      final client = WebAuthnServiceClient(
        baseUrl: webauthnServiceUrl,
        apiKey: webauthnServiceApiKey,
      );

      final options = await client.getSignInOptions(
        rpId: rpId,
        origin: rpOrigin,
        allowCredentials: allowCredentials,
      );

      return Response.json(body: options);
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'error': 'Failed to get sign-in options: $e'},
      );
    }
  };
}

