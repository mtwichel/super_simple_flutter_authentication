import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart';

/// Handles Sign in with Apple token verification.
class SignInWithApple {
  /// Creates a new instance of [SignInWithApple].
  const SignInWithApple({required this.bundleId, this.serviceId});

  /// The bundle ID of the iOS/macOS app.
  final String bundleId;

  /// The service ID for web/Android sign-in.
  final String? serviceId;

  /// Verifies an Apple identity token and returns the user's email.
  Future<String> verifyToken(String token) async {
    try {
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
      final payload = (jsonDecode(decodedPayload) as Map)
          .cast<String, dynamic>();

      // Get Apple's public keys
      final response = await http.get(
        Uri.parse('https://appleid.apple.com/auth/keys'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch Apple public keys');
      }

      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
      final keys = (responseJson['keys'] as List).cast<Map<String, dynamic>>();

      // Find the matching key
      final kid = header['kid'] as String?;

      if (kid == null) {
        throw Exception('No key ID in token header');
      }

      final key = keys.firstWhere(
        (Map<String, dynamic> k) => k['kid'] == kid,
        orElse: () => throw Exception('No matching key found'),
      );

      // Convert the key to RSA public key format
      final n = key['n'] as String;
      final e = key['e'] as String;
      final modulus = _base64UrlToBigInt(n);
      final exponent = _base64UrlToBigInt(e);
      final publicKey = RSAPublicKey(modulus, exponent);

      // Verify signature using Pointycastle
      const rsaSha256Oid = '0609608648016503040201';
      final signer = RSASigner(SHA256Digest(), rsaSha256Oid)
        ..init(false, PublicKeyParameter<RSAPublicKey>(publicKey));
      final signedData = Uint8List.fromList(
        utf8.encode('$encodedHeader.$encodedPayload'),
      );
      final signature = Uint8List.fromList(
        base64Url.decode(base64Url.normalize(rawSignature)),
      );
      final isValid = signer.verifySignature(
        signedData,
        RSASignature(signature),
      );
      if (!isValid) {
        throw Exception('Invalid JWT signature');
      }

      // Check the audience (bundle ID or service ID)
      final aud = payload['aud'] as String?;
      if (aud != bundleId && aud != serviceId) {
        throw Exception('Invalid audience');
      }

      // Check the issuer
      final iss = payload['iss'] as String?;
      if (iss != 'https://appleid.apple.com') {
        throw Exception('Invalid issuer');
      }

      // Check expiration
      final exp = payload['exp'] as int?;
      if (exp == null || DateTime.now().millisecondsSinceEpoch ~/ 1000 > exp) {
        throw Exception('Token expired');
      }

      // Get the email
      final email = payload['email'] as String?;
      if (email == null || email.isEmpty) {
        throw Exception('No email in token');
      }

      return email;
    } catch (e) {
      throw Exception('Failed to verify Apple token: $e');
    }
  }

  // Helper to convert base64url to BigInt (copied from Google integration)
  BigInt _base64UrlToBigInt(String input) {
    final normalized = base64Url.normalize(input);
    final bytes = base64Url.decode(normalized);
    return BigInt.parse(
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      radix: 16,
    );
  }
}
