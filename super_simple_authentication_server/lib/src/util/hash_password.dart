import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:meta/meta.dart';
import 'package:super_simple_authentication_server/src/util/create_random_number.dart';

/// A tuple of the hash and the salt.
typedef HashedPassword = ({List<int> hash, List<int> salt});

/// Calculates the hash of a password using the Argon2id algorithm. Returns
/// a tuple of the hash and the salt.
///
/// The hash is then peppered using the HMAC algorithm with the provided pepper.
///
/// If no pepper is provided, the value of the `PASSWORD_PEPPER` environment
/// variable is used (as a base64 encoded string). If that is null, the hash is
/// not peppered.
Future<HashedPassword> calculatePasswordHash(
  String password, {
  int parallelism = 1,
  int memory = 19000,
  int iterations = 2,
  int hashLength = 32,
  List<int>? pepper,
  List<int>? salt,
  @visibleForTesting Argon2id? argon2id,
  @visibleForTesting Hmac? hmac,
}) async {
  final resolvedArgon2id =
      argon2id ??
      Argon2id(
        parallelism: parallelism,
        memory: memory,
        iterations: iterations,
        hashLength: hashLength,
      );

  final resolvedSalt = salt ?? generateRandomNumber();
  final hashedPassword = await resolvedArgon2id.deriveKeyFromPassword(
    password: password,
    nonce: resolvedSalt,
  );
  final hashedPasswordBytes = await hashedPassword.extractBytes();
  final pepperEnvironmentVariable = Platform.environment['PASSWORD_PEPPER'];
  final resolvedPepper =
      pepper ??
      (pepperEnvironmentVariable == null
          ? null
          : base64.decode(pepperEnvironmentVariable));

  if (resolvedPepper == null) {
    return (hash: hashedPasswordBytes, salt: resolvedSalt);
  }

  final resolvedHmac = hmac ?? Hmac.sha256();
  final mac = await resolvedHmac.calculateMac(
    hashedPasswordBytes,
    secretKey: SecretKey(resolvedPepper),
  );

  return (hash: mac.bytes, salt: resolvedSalt);
}
