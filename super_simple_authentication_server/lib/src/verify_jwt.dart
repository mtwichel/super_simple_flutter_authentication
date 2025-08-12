import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:meta/meta.dart';

/// Verifies a JWT and returns the payload if the signature is valid.
///
/// If the signature is invalid, the function returns `null`.
Future<Map<String, dynamic>?> verifyJwt(
  String jwt, {
  String? secretKey,
  @visibleForTesting Hmac? hmac,
}) async {
  final [encodedHeader, encodedPayload, encodedSignature] = jwt.split('.');

  // Add padding if needed to make length a multiple of 4
  final paddedSignature = encodedSignature.padRight(
    ((encodedSignature.length + 3) ~/ 4) * 4,
    '=',
  );
  final existingSignatureBytes = base64Url.decode(paddedSignature);

  final resolvedSecretKey =
      secretKey ?? Platform.environment['JWT_SECRET_KEY']!;

  final resolvedHmac = hmac ?? Hmac.sha256();
  final secretKeyBytes = SecretKey(base64Url.decode(resolvedSecretKey));

  final signatureInput = '$encodedHeader.$encodedPayload';
  final signatureBytes = await resolvedHmac.calculateMac(
    utf8.encode(signatureInput),
    secretKey: secretKeyBytes,
  );

  if (signatureBytes.bytes.length != existingSignatureBytes.length) {
    return null;
  }

  for (var i = 0; i < signatureBytes.bytes.length; i++) {
    if (signatureBytes.bytes[i] != existingSignatureBytes[i]) {
      return null;
    }
  }

  final payload = Map<String, dynamic>.from(
    json.decode(
          utf8.decode(
            base64Url.decode(
              encodedPayload.padRight(
                ((encodedPayload.length + 3) ~/ 4) * 4,
                '=',
              ),
            ),
          ),
        )
        as Map,
  );
  return payload;
}
