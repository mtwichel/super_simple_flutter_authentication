import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:pointycastle/export.dart';

/// Hashes an OTP using SHA-256.
Future<String> hashOtp(
  String otp, {
  @visibleForTesting Digest? algorithm,
}) async {
  final resolvedAlgorithm = algorithm ?? SHA256Digest();
  final otpBytes = utf8.encode(otp);
  final hash = resolvedAlgorithm.process(Uint8List.fromList(otpBytes));
  return base64.encode(hash);
}
