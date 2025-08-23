// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:super_simple_authentication_server/src/util/rsa_key_manager.dart';

/// Utility script to extract the public key from a private key.
/// This is useful for setting up environment variables.
void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run extract_public_key.dart <private_key_file>');
    print(
      'Or set JWT_PRIVATE_KEY environment variable and run without arguments',
    );
    exit(1);
  }

  try {
    String privateKeyPem;

    if (args.length == 1 && args[0] == '--env') {
      // Read from environment variable
      privateKeyPem = RsaKeyManager.loadPrivateKey();
    } else {
      // Read from file
      final privateKeyFile = File(args[0]);
      if (!privateKeyFile.existsSync()) {
        print('Error: Private key file not found: ${args[0]}');
        exit(1);
      }
      privateKeyPem = await privateKeyFile.readAsString();
    }

    // Extract public key
    final publicKeyPem = await RsaKeyManager.extractPublicKey(privateKeyPem);

    // Generate key ID
    final keyId = await RsaKeyManager.generateKeyId(privateKeyPem);

    // Generate JWK
    final jwk = await RsaKeyManager.extractPublicKeyJwk(
      privateKeyPem,
      keyId: keyId,
    );

    print('=== Public Key (PEM) ===');
    print(publicKeyPem);
    print('\n=== Key ID ===');
    print(keyId);
    print('\n=== JWK ===');
    print(const JsonEncoder.withIndent('  ').convert(jwk));
    print('\n=== JWKS ===');
    print(
      const JsonEncoder.withIndent('  ').convert({
        'keys': [jwk],
      }),
    );
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}
