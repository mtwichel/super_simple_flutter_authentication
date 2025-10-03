import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:pointycastle/export.dart';
import 'package:super_simple_authentication_toolkit/src/util/rsa_key_manager.dart';

/// Creates a JWT with asymmetric signing using RSA.
Future<String> createAsymmetricJwt({
  required bool? isNewUser,
  Duration validFor = const Duration(hours: 1),
  Duration notBefore = Duration.zero,
  String? audience,
  String? subject,
  String? issuer,
  String? keyId,
  String? jwksUrl,
  Map<String, dynamic> additionalClaims = const {},
  @visibleForTesting RSAPrivateKey? testPrivateKey,
}) async {
  final payload = {
    ...additionalClaims,
    if (audience != null) 'aud': audience,
    if (subject != null) 'sub': subject,
    if (issuer != null) 'iss': issuer,
    if (notBefore != Duration.zero)
      'nbf': DateTime.now().add(notBefore).toUtc().toUnixTimestamp(),
    'iat': DateTime.now().toUtc().toUnixTimestamp(),
    'exp': DateTime.now().add(validFor).toUtc().toUnixTimestamp(),
    if (isNewUser != null) 'new': isNewUser,
  };

  // Create the header with RS256 algorithm and optional key ID
  final header = {
    'alg': 'RS256',
    'typ': 'JWT',
    if (keyId != null) 'kid': keyId,
    if (jwksUrl != null) 'jku': jwksUrl,
  };

  // Encode header and payload
  final encodedHeader = base64Url
      .encode(utf8.encode(json.encode(header)))
      .replaceAll('=', '');
  final encodedPayload = base64Url
      .encode(utf8.encode(json.encode(payload)))
      .replaceAll('=', '');

  // Create the signature input
  final signatureInput = '$encodedHeader.$encodedPayload';

  // Get the private key
  RSAPrivateKey privateKey;
  if (testPrivateKey != null) {
    privateKey = testPrivateKey;
  } else {
    final privateKeyPem = RsaKeyManager.loadPrivateKey();
    privateKey = RsaKeyManager.decodePrivateKeyPem(privateKeyPem);
  }

  // Create the signature using RSA-SHA256
  final signatureBytes = RsaKeyManager.signRsaSha256(
    utf8.encode(signatureInput),
    privateKey,
  );

  final encodedSignature = base64Url.encode(signatureBytes).replaceAll('=', '');

  // Combine all parts to create the JWT
  return '$encodedHeader.$encodedPayload.$encodedSignature';
}

extension on DateTime {
  int toUnixTimestamp() => millisecondsSinceEpoch ~/ 1000;
}
