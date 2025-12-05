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
}

/// A user.
typedef User = ({
  String id,
  String? email,
  String? phoneNumber,
  String? hashedPassword,
  String? salt,
});
