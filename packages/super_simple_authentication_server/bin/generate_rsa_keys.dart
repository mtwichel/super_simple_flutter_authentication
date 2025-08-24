// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:super_simple_authentication_toolkit/src/util/rsa_key_manager.dart';

/// Utility script to generate RSA key pairs for testing.
/// This generates both private and public keys in PEM format.
void main(List<String> args) async {
  try {
    print('Generating RSA key pair...');

    // Generate a new RSA key pair
    final privateKeyPem = await RsaKeyManager.generateKeyPair();

    // Extract the public key
    final publicKeyPem = await RsaKeyManager.extractPublicKey(privateKeyPem);

    // Generate key ID
    final keyId = await RsaKeyManager.generateKeyId(privateKeyPem);

    // Generate JWK
    final jwk = await RsaKeyManager.extractPublicKeyJwk(
      privateKeyPem,
      keyId: keyId,
    );

    print('\n=== Private Key (PEM) ===');
    print('Add this to your .env file as JWT_RSA_PRIVATE_KEY:');
    print(privateKeyPem);

    print('\n=== Public Key (PEM) ===');
    print('Add this to your .env file as JWT_RSA_PUBLIC_KEY:');
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

    // Optionally save to files
    if (args.contains('--save')) {
      await File('private_key.pem').writeAsString(privateKeyPem);
      await File('public_key.pem').writeAsString(publicKeyPem);
      await File('jwks.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'keys': [jwk],
        }),
      );
      print('\n=== Files saved ===');
      print('private_key.pem - Private key in PEM format');
      print('public_key.pem - Public key in PEM format');
      print('jwks.json - JWKS (JSON Web Key Set)');
    }
  } catch (e) {
    print('Error generating RSA keys: $e');
    exit(1);
  }
}
