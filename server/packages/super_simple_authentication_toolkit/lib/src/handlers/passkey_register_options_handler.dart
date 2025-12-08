import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:super_simple_authentication_toolkit/super_simple_authentication_toolkit.dart';
import 'package:super_simple_authentication_toolkit/src/webauthn/webauthn_service_client.dart';

/// Handler for getting passkey registration options.
Handler passkeyRegisterOptionsHandler() {
  return (context) async {
    if (context.request.method != HttpMethod.post) {
      return Response(statusCode: HttpStatus.methodNotAllowed);
    }

    final environment = context.read<Environment>();
    final webauthnServiceUrl = environment['WEBAUTHN_SERVICE_URL'];
    final webauthnServiceApiKey = environment['WEBAUTHN_SERVICE_API_KEY'];
    final rpId = environment['RP_ID'];
    final rpName = environment['RP_NAME'] ?? 'Super Simple Auth';
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
      final userId = body?['userId'] as String?;
      final userName = body?['userName'] as String?;
      final userDisplayName = body?['userDisplayName'] as String?;

      final client = WebAuthnServiceClient(
        baseUrl: webauthnServiceUrl,
        apiKey: webauthnServiceApiKey,
      );

      final options = await client.getRegistrationOptions(
        rpId: rpId,
        rpName: rpName,
        origin: rpOrigin,
        userId: userId,
        userName: userName,
        userDisplayName: userDisplayName,
      );

      return Response.json(body: options);
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'error': 'Failed to get registration options: $e'},
      );
    }
  };
}

