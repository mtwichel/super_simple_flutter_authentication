# Asymmetric JWT Setup Guide

This document outlines what you need to do outside of the code to implement asymmetric JWT signing in your authentication server.

## Overview

The implementation now supports both symmetric (HS256) and asymmetric (RS256) JWT signing, similar to Firebase Authentication. The system automatically detects the signing algorithm from the JWT header and validates accordingly.

## Environment Variables Required

### For Asymmetric Signing (RS256)

1. **JWT_PRIVATE_KEY** or **JWT_RSA_PRIVATE_KEY**: Your RSA private key in PEM format
2. **JWT_PUBLIC_KEY** or **JWT_RSA_PUBLIC_KEY**: Your RSA public key in PEM format (for verification)

### For Symmetric Signing (HS256) - Still Supported

1. **JWT_SECRET_KEY**: Your HMAC secret key (base64 encoded)

## Key Generation

### Option 1: Generate New Key Pair

You can generate a new RSA key pair using the provided utilities:

```bash
# Generate a new key pair
dart run lib/src/util/rsa_key_manager.dart
```

### Option 2: Use OpenSSL

```bash
# Generate private key
openssl genrsa -out private_key.pem 2048

# Extract public key
openssl rsa -in private_key.pem -pubout -out public_key.pem
```

### Option 3: Use Existing Keys

If you already have RSA keys, ensure they are in PEM format and compatible with the cryptography library.

## Environment Setup

### Development Environment

1. **Generate or obtain your RSA key pair**
2. **Set environment variables**:

```bash
# For asymmetric signing
export JWT_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
-----END PRIVATE KEY-----"

export JWT_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...
-----END PUBLIC KEY-----"

# Keep the symmetric key for backward compatibility
export JWT_SECRET_KEY="your-existing-secret-key"
```

### Production Environment

1. **Store keys securely**: Use your platform's secret management service (AWS Secrets Manager, Google Secret Manager, Azure Key Vault, etc.)
2. **Key rotation**: Implement a key rotation strategy
3. **Monitoring**: Set up monitoring for JWT validation failures

## Key Management Considerations

### Key Rotation

The implementation supports key rotation through the `kid` (Key ID) header in JWTs. When rotating keys:

1. Generate a new key pair
2. Update the JWKS endpoint to include both old and new keys
3. Gradually migrate to the new key
4. Remove the old key after migration period

### Key Storage

- **Private keys**: Store securely, never expose in client-side code
- **Public keys**: Can be exposed via the JWKS endpoint
- **Environment variables**: Use your platform's secure environment variable management

## API Endpoints

### New Endpoint: `/jwks`

- **Purpose**: Serves public keys in JWKS (JSON Web Key Set) format
- **Format**: JSON containing an array of public keys
- **Caching**: Includes cache headers for 1 hour
- **Usage**: Clients can fetch public keys to verify JWTs

Example response:
```json
{
  "keys": [
    {
      "kty": "RSA",
      "use": "sig",
      "alg": "RS256",
      "kid": "abc123",
      "n": "modulus...",
      "e": "AQAB"
    }
  ]
}
```

## Client Integration

### JWT Verification

Clients should:

1. **Fetch public keys** from `/jwks` endpoint
2. **Extract key ID** from JWT header (`kid`)
3. **Find matching public key** in JWKS
4. **Verify signature** using the public key

### Example Client Flow

```javascript
// 1. Fetch JWKS
const jwks = await fetch('/jwks').then(r => r.json());

// 2. Verify JWT
const token = 'your.jwt.token';
const header = JSON.parse(atob(token.split('.')[0]));
const keyId = header.kid;

// 3. Find matching key
const publicKey = jwks.keys.find(k => k.kid === keyId);

// 4. Verify signature
// (implementation depends on your JWT library)
```

## Migration Strategy

### From Symmetric to Asymmetric

1. **Deploy new code** with asymmetric support
2. **Generate RSA key pair** and set environment variables
3. **Update clients** to use asymmetric verification
4. **Gradually migrate** existing tokens
5. **Remove symmetric key** after migration period

### Backward Compatibility

The system maintains backward compatibility:
- Existing HS256 tokens continue to work
- New tokens can use RS256
- Verification automatically detects algorithm

## Security Considerations

### Key Security

- **Private key protection**: Never expose private keys
- **Key size**: Use at least 2048-bit RSA keys
- **Key rotation**: Implement regular key rotation
- **Access control**: Limit access to private keys

### Token Security

- **Expiration**: Set appropriate token expiration times
- **Audience validation**: Validate token audience
- **Issuer validation**: Validate token issuer
- **Clock skew**: Account for clock differences

## Testing

### Generate Test Keys

```bash
# Generate test key pair
dart run lib/src/util/extract_public_key.dart --env
```

### Test JWT Creation

```dart
// Create asymmetric JWT
final token = await createJwtAsymmetric(
  subject: 'user123',
  isNewUser: false,
  keyId: 'test-key-1',
);
```

### Test JWT Verification

```dart
// Verify JWT (automatically detects algorithm)
final payload = await verifyJwt(token);
```

## Monitoring and Logging

### Key Metrics to Monitor

- JWT creation success/failure rates
- JWT verification success/failure rates
- Algorithm usage distribution (HS256 vs RS256)
- Key rotation events
- JWKS endpoint access patterns

### Logging

- Log JWT creation with algorithm and key ID
- Log JWT verification attempts and results
- Log key rotation events
- Log JWKS endpoint access

## Troubleshooting

### Common Issues

1. **"Private key not found"**: Check environment variables
2. **"Public key not found"**: Ensure public key is set for verification
3. **"Invalid signature"**: Verify key pair matches
4. **"Unsupported algorithm"**: Check JWT header algorithm

### Debug Commands

```bash
# Extract public key from private key
dart run lib/src/util/extract_public_key.dart private_key.pem

# Generate new key pair
dart run lib/src/util/rsa_key_manager.dart
```

## Performance Considerations

### Caching

- **JWKS caching**: Clients should cache JWKS responses
- **Public key caching**: Cache public keys in memory
- **Token validation**: Consider caching validation results

### Key Size Impact

- **2048-bit RSA**: Good balance of security and performance
- **4096-bit RSA**: Higher security, slower operations
- **Key generation**: Generate keys during deployment, not runtime

## Compliance and Standards

### JWT Standards

- **RFC 7519**: JSON Web Token
- **RFC 7517**: JSON Web Key
- **RFC 7518**: JSON Web Algorithms

### Security Standards

- **OWASP**: Follow OWASP JWT guidelines
- **NIST**: Use NIST-approved key sizes
- **Industry**: Follow industry best practices for key management