import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Hashes an OTP using SHA-256.
Future<String> hashOtp(String otp) async {
  final algorithm = Sha256();
  final hash = await algorithm.hash(utf8.encode(otp));
  return base64.encode(hash.bytes);
}
