# Implementation Plan

- [x] 1. Create core data models and interfaces

  - Create OAuthUserInfo class to standardize user information extracted from tokens
  - Create OAuthProviderConfig class to hold provider-specific configuration
  - Create OAuthVerificationException class for structured error handling
  - Write unit tests for all data model classes
  - _Requirements: 5.4, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

- [x] 2. Implement JWKS key caching system

  - Create JwksKeyCache class with HTTP client for fetching provider public keys
  - Implement cache expiration and refresh logic with configurable durations
  - Add support for RSA and ECDSA key parsing from JWKS format
  - Write unit tests for key caching, expiration, and network failure scenarios
  - _Requirements: 4.5, 3.4_

- [-] 3. Create OAuth provider configuration registry

  - Implement OAuthProviderRegistry class for managing multiple provider configurations
  - Add support for loading configurations from environment variables
  - Add support for loading configurations from JSON files with environment variable substitution
  - Implement OpenID Connect auto-discovery for JWKS endpoints
  - Write unit tests for configuration loading, provider registration, and lookup
  - _Requirements: 1.1, 1.3, 3.1, 3.2, 3.3_

- [ ] 4. Implement generic OAuth token verification

  - Create GenericOAuthVerifier class with JWT parsing and validation logic
  - Implement signature verification using cached public keys from JWKS endpoints
  - Add validation for standard JWT claims (iss, aud, exp, iat, sub)
  - Implement user information extraction with claim mapping support
  - Write comprehensive unit tests for token verification, signature validation, and claims checking
  - _Requirements: 1.2, 4.1, 4.2, 4.3, 4.4, 5.1, 5.2, 5.3, 5.5_

- [ ] 5. Update existing provider classes for backward compatibility

  - Modify SignInWithGoogle class to use GenericOAuthVerifier internally while maintaining same public API
  - Modify SignInWithApple class to use GenericOAuthVerifier internally while maintaining same public API
  - Ensure all existing functionality continues to work exactly as before
  - Write integration tests to verify backward compatibility
  - _Requirements: 2.1, 2.2, 2.3_

- [ ] 6. Update credential handler to support generic OAuth

  - Modify signInWithCredentialHandler to use OAuthProviderRegistry for provider lookup
  - Add support for configuring additional OAuth providers beyond Google and Apple
  - Implement proper error handling with specific error types for different failure scenarios
  - Update error responses to provide meaningful feedback for authentication failures
  - Write integration tests for the updated handler with multiple provider scenarios
  - _Requirements: 1.1, 1.4, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

- [ ] 7. Add configuration loading and initialization

  - Create initialization code to load OAuth provider configurations on application startup
  - Add support for automatic registration of Google and Apple providers from existing environment variables
  - Implement configuration validation to ensure required settings are present
  - Add logging for configuration loading and provider registration
  - Write tests for configuration initialization and validation
  - _Requirements: 3.1, 3.2, 3.3, 2.4_

- [ ] 8. Create comprehensive integration tests
  - Write end-to-end tests for Google OAuth token verification using the generic system
  - Write end-to-end tests for Apple OAuth token verification using the generic system
  - Create tests for custom OAuth provider configuration and verification
  - Test error scenarios including network failures, invalid tokens, and missing configurations
  - Verify that existing SignInWithGoogle and SignInWithApple classes work unchanged
  - _Requirements: 1.2, 2.1, 2.2, 2.3, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_
