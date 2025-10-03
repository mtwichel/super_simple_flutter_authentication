import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:pointycastle/export.dart';

/// Creates a JWT for the given email.
Future<String> createSymmetricJwt({
  required bool? isNewUser,
  required String secretKey,
  Duration validFor = const Duration(hours: 1),
  Duration notBefore = Duration.zero,
  String? audience,
  String? subject,
  String? issuer,
  Map<String, dynamic> additionalClaims = const {},
  @visibleForTesting HMac? hmac,
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

  // Create the header
  final header = {'alg': 'HS256', 'typ': 'JWT'};

  // Encode header and payload
  final encodedHeader = base64Url
      .encode(utf8.encode(json.encode(header)))
      .replaceAll('=', '');
  final encodedPayload = base64Url
      .encode(utf8.encode(json.encode(payload)))
      .replaceAll('=', '');

  // Create the signature input
  final signatureInput = '$encodedHeader.$encodedPayload';

  // Create the signature using HMAC-SHA256
  final resolvedHmac = hmac ?? HMac(SHA256Digest(), 64);
  final secretKeyBytes = base64Url.decode(secretKey);
  resolvedHmac.init(KeyParameter(Uint8List.fromList(secretKeyBytes)));

  final signatureInputBytes = utf8.encode(signatureInput);
  final signatureBytes = resolvedHmac.process(
    Uint8List.fromList(signatureInputBytes),
  );

  final encodedSignature = base64Url.encode(signatureBytes).replaceAll('=', '');

  // Combine all parts to create the JWT
  return '$encodedHeader.$encodedPayload.$encodedSignature';
}

extension on DateTime {
  int toUnixTimestamp() => millisecondsSinceEpoch ~/ 1000;
}
