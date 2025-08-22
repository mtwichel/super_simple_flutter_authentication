import 'dart:convert';
import 'dart:io';

import 'package:super_simple_authentication_server/src/util/create_jwt_asymmetric.dart';
import 'package:super_simple_authentication_server/src/verify_jwt.dart';
import 'package:super_simple_authentication_server/src/util/rsa_key_manager.dart';

/// Example usage of asymmetric JWT functionality
void main() async {
  print('=== Asymmetric JWT Example ===\n');

  try {
    // Step 1: Generate a key pair (in production, you'd load from environment)
    print('1. Generating RSA key pair...');
    final privateKeyPem = await RsaKeyManager.generateKeyPair();
    final publicKeyPem = await RsaKeyManager.extractPublicKey(privateKeyPem);
    final keyId = await RsaKeyManager.generateKeyId(privateKeyPem);
    
    print('✓ Key pair generated successfully');
    print('✓ Key ID: $keyId\n');

    // Step 2: Set environment variables (simulating production setup)
    print('2. Setting up environment variables...');
    Platform.environment['JWT_PRIVATE_KEY'] = privateKeyPem;
    Platform.environment['JWT_PUBLIC_KEY'] = publicKeyPem;
    print('✓ Environment variables set\n');

    // Step 3: Create an asymmetric JWT
    print('3. Creating asymmetric JWT...');
    final token = await createJwtAsymmetric(
      subject: 'user123',
      isNewUser: false,
      keyId: keyId,
      issuer: 'my-auth-server',
      audience: 'my-app',
      additionalClaims: {
        'email': 'user@example.com',
        'role': 'user',
      },
    );
    
    print('✓ JWT created successfully');
    print('Token: $token\n');

    // Step 4: Verify the JWT
    print('4. Verifying JWT...');
    final payload = await verifyJwt(token);
    
    if (payload != null) {
      print('✓ JWT verified successfully');
      print('Payload: ${JsonEncoder.withIndent('  ').convert(payload)}\n');
    } else {
      print('✗ JWT verification failed\n');
      return;
    }

    // Step 5: Generate JWKS
    print('5. Generating JWKS...');
    final jwks = await RsaKeyManager.generateJwks(privateKeyPem, keyId: keyId);
    print('✓ JWKS generated successfully');
    print('JWKS: ${JsonEncoder.withIndent('  ').convert(jwks)}\n');

    // Step 6: Demonstrate header parsing
    print('6. Parsing JWT header...');
    final parts = token.split('.');
    final header = json.decode(
      utf8.decode(base64Url.decode(parts[0])),
    ) as Map<String, dynamic>;
    
    print('✓ Header parsed successfully');
    print('Algorithm: ${header['alg']}');
    print('Type: ${header['typ']}');
    print('Key ID: ${header['kid']}\n');

    // Step 7: Test with wrong public key (should fail)
    print('7. Testing with wrong public key...');
    final wrongPrivateKey = await RsaKeyManager.generateKeyPair();
    final wrongPublicKey = await RsaKeyManager.extractPublicKey(wrongPrivateKey);
    
    Platform.environment['JWT_PUBLIC_KEY'] = wrongPublicKey;
    final wrongPayload = await verifyJwt(token);
    
    if (wrongPayload == null) {
      print('✓ Verification correctly failed with wrong key');
    } else {
      print('✗ Verification should have failed with wrong key');
    }

    print('\n=== Example completed successfully ===');
    
  } catch (e) {
    print('Error: $e');
  }
}