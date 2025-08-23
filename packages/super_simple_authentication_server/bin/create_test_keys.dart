// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/asn1/primitives/asn1_bit_string.dart';
import 'package:pointycastle/asn1/primitives/asn1_integer.dart';
import 'package:pointycastle/asn1/primitives/asn1_null.dart';
import 'package:pointycastle/asn1/primitives/asn1_object_identifier.dart';
import 'package:pointycastle/asn1/primitives/asn1_sequence.dart';
import 'package:pointycastle/export.dart';

/// Creates a simple RSA key pair for testing
void main(List<String> args) async {
  try {
    print('Generating RSA key pair for testing...');

    // Create a simple RSA key pair
    final keyGen = RSAKeyGenerator();
    final secureRandom = SecureRandom('Fortuna');
    final random = Random.secure();
    final seed = List<int>.generate(32, (i) => random.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seed)));

    keyGen.init(
      ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 64),
        secureRandom,
      ),
    );

    final keyPair = keyGen.generateKeyPair();
    final privateKey = keyPair.privateKey;
    final publicKey = keyPair.publicKey;

    // Create PEM format for private key
    final privateKeyPem = _createPrivateKeyPem(privateKey);
    final publicKeyPem = _createPublicKeyPem(publicKey);

    print('\n=== Private Key (PEM) ===');
    print('Add this to your .demo.env file as JWT_RSA_PRIVATE_KEY:');
    print(privateKeyPem);

    print('\n=== Public Key (PEM) ===');
    print('Add this to your .demo.env file as JWT_RSA_PUBLIC_KEY:');
    print(publicKeyPem);

    // Save to files
    await File('test_private_key.pem').writeAsString(privateKeyPem);
    await File('test_public_key.pem').writeAsString(publicKeyPem);

    print('\n=== Files saved ===');
    print('test_private_key.pem - Private key in PEM format');
    print('test_public_key.pem - Public key in PEM format');
  } catch (e) {
    print('Error generating RSA keys: $e');
    exit(1);
  }
}

String _createPrivateKeyPem(RSAPrivateKey privateKey) {
  // Create ASN.1 sequence for RSA private key
  final asn1Seq = ASN1Sequence(
    elements: [
      ASN1Integer.fromtInt(0), // version
      ASN1Integer.fromBytes(_bigIntToBytes(privateKey.modulus!)),
      ASN1Integer.fromBytes(
        _bigIntToBytes(BigInt.from(65537)),
      ), // public exponent
      ASN1Integer.fromBytes(_bigIntToBytes(privateKey.privateExponent!)),
      ASN1Integer.fromBytes(_bigIntToBytes(privateKey.p!)),
      ASN1Integer.fromBytes(_bigIntToBytes(privateKey.q!)),
      ASN1Integer.fromBytes(
        _bigIntToBytes(
          privateKey.privateExponent! % (privateKey.p! - BigInt.one),
        ),
      ),
      ASN1Integer.fromBytes(
        _bigIntToBytes(
          privateKey.privateExponent! % (privateKey.q! - BigInt.one),
        ),
      ),
      ASN1Integer.fromBytes(
        _bigIntToBytes(privateKey.q! * privateKey.q!.modInverse(privateKey.p!)),
      ),
    ],
  );

  final keyBytes = asn1Seq.encode();
  final base64Key = base64.encode(keyBytes);

  final pemLines = <String>['-----BEGIN PRIVATE KEY-----'];

  for (var i = 0; i < base64Key.length; i += 64) {
    final end = (i + 64 < base64Key.length) ? i + 64 : base64Key.length;
    pemLines.add(base64Key.substring(i, end));
  }

  pemLines.add('-----END PRIVATE KEY-----');
  return pemLines.join('\n');
}

String _createPublicKeyPem(RSAPublicKey publicKey) {
  // Create ASN.1 sequence for RSA public key
  final asn1Seq = ASN1Sequence(
    elements: [
      ASN1Sequence(
        elements: [
          ASN1ObjectIdentifier.fromIdentifierString(
            '1.2.840.113549.1.1.1',
          ), // RSA algorithm
          ASN1Null(),
        ],
      ),
      ASN1BitString(stringValues: _encodePublicKeyAsn1(publicKey).toList()),
    ],
  );

  final keyBytes = asn1Seq.encode();
  final base64Key = base64.encode(keyBytes);

  final pemLines = <String>['-----BEGIN PUBLIC KEY-----'];

  for (var i = 0; i < base64Key.length; i += 64) {
    final end = (i + 64 < base64Key.length) ? i + 64 : base64Key.length;
    pemLines.add(base64Key.substring(i, end));
  }

  pemLines.add('-----END PUBLIC KEY-----');
  return pemLines.join('\n');
}

Uint8List _encodePublicKeyAsn1(RSAPublicKey publicKey) {
  final asn1Seq = ASN1Sequence(
    elements: [
      ASN1Integer.fromBytes(_bigIntToBytes(publicKey.modulus!)),
      ASN1Integer.fromBytes(_bigIntToBytes(publicKey.exponent!)),
    ],
  );
  return asn1Seq.encode();
}

Uint8List _bigIntToBytes(BigInt value) {
  final hexString = value.toRadixString(16);
  final paddedHex = hexString.length.isEven ? hexString : '0$hexString';

  final byteList = <int>[];
  for (var i = 0; i < paddedHex.length; i += 2) {
    byteList.add(int.parse(paddedHex.substring(i, i + 2), radix: 16));
  }

  // Remove leading zeros
  var startIndex = 0;
  while (startIndex < byteList.length - 1 && byteList[startIndex] == 0) {
    startIndex++;
  }

  return Uint8List.fromList(byteList.sublist(startIndex));
}
