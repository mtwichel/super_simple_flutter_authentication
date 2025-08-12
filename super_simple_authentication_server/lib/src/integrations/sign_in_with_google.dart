import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart';

/// {@template sign_in_with_google}
/// A class to handle Google Sign-In token verification.
/// It verifies the JWT token, checks the signature, and extracts the email.
/// {@endtemplate}
class SignInWithGoogle {
  /// Creates an instance of [SignInWithGoogle].
  SignInWithGoogle({required String clientId}) : _clientId = clientId;
  final String _clientId;

  /// OID for RSA with SHA-256 (PKCS#1 v1.5)
  static const _rsaSha256Oid = '0609608648016503040201';

  /// Verifies the provided JWT token and extracts the email.
  Future<String> verifyToken(String token) async {
    // Parse JWT
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid JWT format');
    }
    final [encodedHeader, encodedPayload, rawSignature] = parts;
    final decodedHeader = utf8.decode(
      base64Url.decode(base64Url.normalize(encodedHeader)),
    );
    final decodedPayload = utf8.decode(
      base64Url.decode(base64Url.normalize(encodedPayload)),
    );
    if (decodedHeader.isEmpty || decodedPayload.isEmpty) {
      throw Exception('Invalid JWT header or payload');
    }
    final header = (jsonDecode(decodedHeader) as Map).cast<String, dynamic>();
    final payload = (jsonDecode(decodedPayload) as Map).cast<String, dynamic>();

    // Fetch Google's public keys
    const jwksUri = 'https://www.googleapis.com/oauth2/v3/certs';
    final jwksResponse = await http.get(Uri.parse(jwksUri));
    if (jwksResponse.statusCode != 200) {
      throw Exception('Failed to fetch Google public keys');
    }
    final jwks = jsonDecode(jwksResponse.body) as Map<String, dynamic>;
    final keys = (jwks['keys'] as List).cast<Map<String, dynamic>>();

    // Find the key with the matching kid
    final kid = header['kid'] as String?;
    final key = keys.firstWhere((k) => k['kid'] == kid, orElse: () => {});
    if (key.isEmpty) {
      throw Exception('No matching key found for kid');
    }

    // Verify signature using Pointycastle
    final n = key['n'] as String;
    final e = key['e'] as String;
    final modulus = _base64UrlToBigInt(n);
    final exponent = _base64UrlToBigInt(e);
    final publicKey = RSAPublicKey(modulus, exponent);
    final signer = RSASigner(SHA256Digest(), _rsaSha256Oid)
      ..init(false, PublicKeyParameter<RSAPublicKey>(publicKey));
    final signedData = Uint8List.fromList(
      utf8.encode('$encodedHeader.$encodedPayload'),
    );
    final signature = Uint8List.fromList(
      base64Url.decode(base64Url.normalize(rawSignature)),
    );
    final isValid = signer.verifySignature(signedData, RSASignature(signature));
    if (!isValid) {
      throw Exception('Invalid JWT signature');
    }

    // Validate claims
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final exp = payload['exp'];
    if (exp is! int || exp < now) {
      throw Exception('JWT expired or invalid exp');
    }
    if (payload['aud'] != _clientId) {
      throw Exception('Invalid audience');
    }
    if (payload['iss'] != 'https://accounts.google.com' &&
        payload['iss'] != 'accounts.google.com') {
      throw Exception('Invalid issuer');
    }

    // Extract email
    final extractedEmail = payload['email'] as String?;
    if (extractedEmail == null) {
      throw Exception('Email not found in JWT');
    }
    return extractedEmail;
  }

  // Helper to convert base64url to BigInt
  BigInt _base64UrlToBigInt(String input) {
    final normalized = base64Url.normalize(input);
    final bytes = base64Url.decode(normalized);
    return BigInt.parse(
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      radix: 16,
    );
  }
}
