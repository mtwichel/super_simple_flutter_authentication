/// {@template data_storage}
/// A data storage interface for the authentication server.
/// {@endtemplate}
abstract class DataStorage {
  /// {@macro data_storage}
  const DataStorage();

  /// Creates a new user and returns the user ID.
  Future<String> createUser({
    String? email,
    String? phoneNumber,
    String? hashedPassword,
    String? salt,
  });

  /// Creates a new session and returns the session ID.
  Future<String> createSession(String userId);

  /// Creates a new refresh token and returns the refresh token.
  Future<void> createRefreshToken({
    required String sessionId,
    required String refreshToken,
    required String userId,
    String? parentToken,
  });

  /// Gets a refresh token by its token.
  Future<({String userId, String sessionId, bool revoked})> getRefreshToken({
    required String refreshToken,
  });

  /// Revokes a refresh token by its token.
  Future<void> revokeRefreshToken({required String refreshToken});

  /// Updates a session by its ID.
  Future<void> updateSession({
    required String sessionId,
    required String refreshedAt,
  });

  /// Revokes OTPs for a given identifier and channel.
  Future<void> revokeOtpsFor({
    required String identifier,
    required String channel,
  });

  /// Creates an OTP for a given identifier and channel.
  Future<void> createOtp({
    required String identifier,
    required String channel,
    required String hashedOtp,
    required String expiresAt,
  });

  /// Gets an OTP by its identifier and channel.
  Future<String?> getOtpFor({
    required String identifier,
    required String channel,
    required String now,
  });

  /// Gets users by email.
  Future<List<User>> getUsersByEmail(String email);

  /// Gets users by phone number.
  Future<List<User>> getUsersByPhoneNumber(String phoneNumber);

  /// Creates a password reset token for a user.
  Future<void> createPasswordResetToken({
    required String userId,
    required String hashedToken,
    required String expiresAt,
  });

  /// Gets a password reset token by its token.
  ///
  /// Returns the user ID if the token is valid and not expired, null otherwise.
  Future<({String? userId, bool expired})> getPasswordResetToken({
    required String token,
    required String now,
  });

  /// Revokes all password reset tokens for a user.
  Future<void> revokePasswordResetTokens({required String userId});

  /// Updates a user's password and salt.
  Future<void> updateUserPassword({
    required String userId,
    required String hashedPassword,
    required String salt,
  });

  /// Creates a new passkey credential for a user.
  Future<void> createPasskeyCredential({
    required String userId,
    required List<int> credentialId,
    required List<int> publicKey,
    required int signCount,
    List<int>? userHandle,
  });

  /// Gets a passkey credential by its credential ID.
  Future<PasskeyCredential?> getPasskeyCredentialByCredentialId({
    required List<int> credentialId,
  });

  /// Gets all passkey credentials for a user.
  Future<List<PasskeyCredential>> getPasskeyCredentialsByUserId({
    required String userId,
  });

  /// Updates the sign count for a passkey credential.
  Future<void> updatePasskeySignCount({
    required List<int> credentialId,
    required int signCount,
  });

  /// Deletes a passkey credential.
  Future<void> deletePasskeyCredential({
    required List<int> credentialId,
  });
}

/// A user.
typedef User = ({
  String id,
  String? email,
  String? phoneNumber,
  String? hashedPassword,
  String? salt,
});

/// A passkey credential.
typedef PasskeyCredential = ({
  String id,
  String userId,
  List<int> credentialId,
  List<int> publicKey,
  int signCount,
  List<int>? userHandle,
});
