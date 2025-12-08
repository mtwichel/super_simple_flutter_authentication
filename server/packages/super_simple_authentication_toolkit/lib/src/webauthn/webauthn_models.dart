/// Models for WebAuthn operations.

/// Public Key Credential Creation Options (for registration).
typedef PublicKeyCredentialCreationOptions = Map<String, dynamic>;

/// Public Key Credential Request Options (for authentication).
typedef PublicKeyCredentialRequestOptions = Map<String, dynamic>;

/// Attestation response from the client (for registration).
typedef AttestationResponse = Map<String, dynamic>;

/// Assertion response from the client (for authentication).
typedef AssertionResponse = Map<String, dynamic>;

/// Verification result from external WebAuthn service.
typedef WebAuthnVerificationResult = ({
  bool success,
  String? credentialId,
  String? userId,
  int? signCount,
  String? publicKey, // Base64-encoded public key
  String? error,
});

