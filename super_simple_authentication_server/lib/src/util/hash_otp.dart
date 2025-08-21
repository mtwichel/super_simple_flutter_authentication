import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:meta/meta.dart';

/// Hashes an OTP using SHA-256.
Future<String> hashOtp(
  String otp, {
  @visibleForTesting HashAlgorithm? algorithm,
}) async {
  final resolvedAlgorithm = algorithm ?? Sha256();
  final hash = await resolvedAlgorithm.hash(utf8.encode(otp));
  return base64.encode(hash.bytes);
}
