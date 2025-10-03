import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:pointycastle/export.dart';
import 'package:super_simple_authentication_toolkit/src/util/create_random_number.dart';

/// A tuple of the hash and the salt.
typedef HashedPassword = ({List<int> hash, List<int> salt});

/// Calculates the hash of a password using PBKDF2 with SHA-256. Returns
/// a tuple of the hash and the salt.
///
/// The hash is then peppered using the HMAC algorithm with the provided pepper.
///
/// If no pepper is provided, the value of the `PASSWORD_PEPPER` environment
/// variable is used (as a base64 encoded string). If that is null, the hash is
/// not peppered.
Future<HashedPassword> calculatePasswordHash(
  String password, {
  int iterations = 100000,
  int hashLength = 32,
  List<int>? pepper,
  List<int>? salt,
  @visibleForTesting PBKDF2KeyDerivator? pbkdf2,
  @visibleForTesting HMac? hmac,
}) async {
  final resolvedSalt = salt ?? generateRandomNumber();

  // Use PBKDF2 with SHA-256 for password hashing
  final resolvedPbkdf2 = pbkdf2 ?? PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
    ..init(
      Pbkdf2Parameters(
        Uint8List.fromList(resolvedSalt),
        iterations,
        hashLength,
      ),
    );

  final passwordBytes = utf8.encode(password);
  final hashedPasswordBytes = resolvedPbkdf2.process(
    Uint8List.fromList(passwordBytes),
  );

  final pepperEnvironmentVariable = Platform.environment['PASSWORD_PEPPER'];
  final resolvedPepper =
      pepper ??
      (pepperEnvironmentVariable == null
          ? null
          : base64.decode(pepperEnvironmentVariable));

  if (resolvedPepper == null) {
    return (hash: hashedPasswordBytes.toList(), salt: resolvedSalt);
  }

  // Apply pepper using HMAC-SHA256
  final resolvedHmac = hmac ?? HMac(SHA256Digest(), 64)
    ..init(KeyParameter(Uint8List.fromList(resolvedPepper)));
  final pepperedHash = resolvedHmac.process(hashedPasswordBytes);

  return (hash: pepperedHash.toList(), salt: resolvedSalt);
}
