import 'package:dart_frog/dart_frog.dart';
import 'package:super_simple_authentication_server/src/util/rsa_key_manager.dart';

/// JWKS (JSON Web Key Set) endpoint that serves public keys for JWT
/// verification.
/// This endpoint is similar to Firebase's JWKS endpoint.
Future<Response> onRequest(RequestContext context) async {
  try {
    // Load the private key to extract the public key
    final privateKeyPem = RsaKeyManager.loadPrivateKey();

    // Generate a key ID for the key
    final keyId = await RsaKeyManager.generateKeyId(privateKeyPem);

    // Generate the JWKS
    final jwks = await RsaKeyManager.generateJwks(privateKeyPem, keyId: keyId);

    return Response.json(
      body: jwks,
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'public, max-age=3600', // Cache for 1 hour
      },
    );
  } catch (e) {
    return Response.json(
      body: {'error': 'Failed to generate JWKS', 'message': e.toString()},
      statusCode: 500,
    );
  }
}
