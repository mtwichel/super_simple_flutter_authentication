import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:pointycastle/export.dart';

/// Hashes a password reset token using SHA-256.
Future<String> hashPasswordResetToken(
  String token, {
  @visibleForTesting Digest? algorithm,
}) async {
  final resolvedAlgorithm = algorithm ?? SHA256Digest();
  final tokenBytes = utf8.encode(token);
  final hash = resolvedAlgorithm.process(Uint8List.fromList(tokenBytes));
  return base64.encode(hash);
}
