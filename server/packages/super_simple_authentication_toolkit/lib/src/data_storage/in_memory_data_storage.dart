import 'dart:convert';

import 'package:super_simple_authentication_toolkit/super_simple_authentication_toolkit.dart';
import 'package:uuid/uuid.dart';

/// {@template in_memory_data_storage}
/// A data storage that stores data in memory.
/// {@endtemplate}
class InMemoryDataStorage implements DataStorage {
  /// {@macro in_memory_data_storage}
  InMemoryDataStorage();

  final Map<String, Map<String, dynamic>?> _data = {};
  static const _uuid = Uuid();

  @override
  Future<void> createOtp({
    required String identifier,
    required String channel,
    required String hashedOtp,
    required String expiresAt,
  }) async {
    _data['otps:$identifier:$channel'] = {
      'otp': hashedOtp,
      'expiresAt': expiresAt,
    };
  }

  @override
  Future<void> createRefreshToken({
    required String sessionId,
    required String refreshToken,
    required String userId,
    String? parentToken,
  }) async {
    _data['refreshToken:$refreshToken'] = {
      'sessionId': sessionId,
      'userId': userId,
      'revoked': false,
      if (parentToken != null) 'parentToken': parentToken,
    };
  }

  @override
  Future<String> createSession(String userId) async {
    final sessionId = _uuid.v4();
    _data['session:$sessionId'] = {'userId': userId};
    return sessionId;
  }

  @override
  Future<String> createUser({
    String? email,
    String? phoneNumber,
    String? hashedPassword,
    String? salt,
  }) async {
    final userId = _uuid.v4();
    _data['user:$userId'] = {
      'email': email,
      'phoneNumber': phoneNumber,
      'hashedPassword': hashedPassword,
      'salt': salt,
    };
    _data['email:$email'] = {'userId': userId};
    _data['phoneNumber:$phoneNumber'] = {'userId': userId};
    return userId;
  }

  @override
  Future<String?> getOtpFor({
    required String identifier,
    required String channel,
    required String now,
  }) async {
    final key = 'otps:$identifier:$channel';
    final otp = _data[key]?['otp'] as String?;
    final expiresAt = _data[key]?['expiresAt'];
    if (otp == null || expiresAt == null) {
      return null;
    }
    return otp;
  }

  @override
  Future<({bool revoked, String sessionId, String userId})> getRefreshToken({
    required String refreshToken,
  }) async {
    final key = 'refreshToken:$refreshToken';
    final data = _data[key];
    if (data == null) {
      return (revoked: false, sessionId: '', userId: '');
    }
    return (
      revoked: data['revoked'] as bool,
      sessionId: data['sessionId'] as String,
      userId: data['userId'] as String,
    );
  }

  @override
  Future<List<User>> getUsersByEmail(String email) async {
    final key = 'email:$email';
    final userId = _data[key]?['userId'] as String?;
    if (userId == null) {
      return [];
    }
    return [
      (
        id: userId,
        email: _data['user:$userId']?['email'] as String?,
        phoneNumber: _data['phoneNumber:$userId']?['phoneNumber'] as String?,
        hashedPassword: _data['user:$userId']?['hashedPassword'] as String?,
        salt: _data['user:$userId']?['salt'] as String?,
      ),
    ];
  }

  @override
  Future<List<User>> getUsersByPhoneNumber(String phoneNumber) async {
    final key = 'phoneNumber:$phoneNumber';
    final userId = _data[key]?['userId'] as String?;
    if (userId == null) {
      return [];
    }
    return [
      (
        id: userId,
        email: _data['user:$userId']?['email'] as String?,
        phoneNumber: _data['phoneNumber:$userId']?['phoneNumber'] as String?,
        hashedPassword: _data['user:$userId']?['hashedPassword'] as String?,
        salt: _data['user:$userId']?['salt'] as String?,
      ),
    ];
  }

  @override
  Future<void> revokeOtpsFor({
    required String identifier,
    required String channel,
  }) async {
    final key = 'otps:$identifier:$channel';
    _data[key] = null;
  }

  @override
  Future<void> revokeRefreshToken({required String refreshToken}) async {
    final key = 'refreshToken:$refreshToken';
    _data[key] = null;
  }

  @override
  Future<void> updateSession({
    required String sessionId,
    required String refreshedAt,
  }) async {
    final key = 'session:$sessionId';
    final existingSession = _data[key];
    if (existingSession == null) {
      return;
    }
    _data[key] = {...existingSession, 'refreshedAt': refreshedAt};
  }

  @override
  Future<void> createPasswordResetToken({
    required String userId,
    required String hashedToken,
    required String expiresAt,
  }) async {
    _data['passwordResetToken:$hashedToken'] = {
      'userId': userId,
      'expiresAt': expiresAt,
    };
  }

  @override
  Future<({String? userId, bool expired})> getPasswordResetToken({
    required String token,
    required String now,
  }) async {
    // Hash the token before lookup since we store hashed tokens
    final hashedToken = await hashPasswordResetToken(token);
    final key = 'passwordResetToken:$hashedToken';
    final tokenData = _data[key];
    if (tokenData == null) {
      return (userId: null, expired: false);
    }
    final expiresAt = tokenData['expiresAt'] as String?;
    if (expiresAt == null) {
      return (userId: null, expired: false);
    }
    if (DateTime.parse(expiresAt).isBefore(DateTime.parse(now))) {
      _data[key] = null;
      return (userId: null, expired: true);
    }
    return (userId: tokenData['userId'] as String, expired: false);
  }

  @override
  Future<void> revokePasswordResetTokens({required String userId}) async {
    // Find all password reset tokens for this user and remove them
    final keysToRemove = <String>[];
    for (final entry in _data.entries) {
      if (entry.key.startsWith('passwordResetToken:') &&
          entry.value?['userId'] == userId) {
        keysToRemove.add(entry.key);
      }
    }
    for (final key in keysToRemove) {
      _data[key] = null;
    }
  }

  @override
  Future<void> updateUserPassword({
    required String userId,
    required String hashedPassword,
    required String salt,
  }) async {
    final key = 'user:$userId';
    final existingUser = _data[key];
    if (existingUser == null) {
      return;
    }
    _data[key] = {
      ...existingUser,
      'hashedPassword': hashedPassword,
      'salt': salt,
    };
  }

  @override
  Future<void> createPasskeyCredential({
    required String userId,
    required List<int> credentialId,
    required List<int> publicKey,
    required int signCount,
    List<int>? userHandle,
  }) async {
    final credentialIdKey = base64Url.encode(credentialId);
    _data['passkeyCredential:$credentialIdKey'] = {
      'userId': userId,
      'credentialId': credentialIdKey,
      'publicKey': base64Url.encode(publicKey),
      'signCount': signCount,
      if (userHandle != null) 'userHandle': base64Url.encode(userHandle),
    };
    // Also store index by userId
    final userCredentials = (_data['passkeyCredentialsByUser:$userId']?['credentials'] as List<dynamic>?)?.cast<String>().toList() ?? <String>[];
    userCredentials.add(credentialIdKey);
    _data['passkeyCredentialsByUser:$userId'] = {'credentials': userCredentials};
  }

  @override
  Future<PasskeyCredential?> getPasskeyCredentialByCredentialId({
    required List<int> credentialId,
  }) async {
    final credentialIdKey = base64Url.encode(credentialId);
    final credentialData = _data['passkeyCredential:$credentialIdKey'];
    if (credentialData == null) {
      return null;
    }
    return (
      id: credentialIdKey,
      userId: credentialData['userId'] as String,
      credentialId: credentialId,
      publicKey: base64Url.decode(credentialData['publicKey'] as String).toList(),
      signCount: credentialData['signCount'] as int,
      userHandle: credentialData['userHandle'] != null
          ? base64Url.decode(credentialData['userHandle'] as String).toList()
          : null,
    );
  }

  @override
  Future<List<PasskeyCredential>> getPasskeyCredentialsByUserId({
    required String userId,
  }) async {
    final credentialIds = (_data['passkeyCredentialsByUser:$userId']?['credentials'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final credentials = <PasskeyCredential>[];
    for (final credentialIdKey in credentialIds) {
      final credentialData = _data['passkeyCredential:$credentialIdKey'];
      if (credentialData != null) {
        credentials.add(
          (
            id: credentialIdKey,
            userId: credentialData['userId'] as String,
            credentialId: base64Url.decode(credentialIdKey).toList(),
            publicKey: base64Url.decode(credentialData['publicKey'] as String).toList(),
            signCount: credentialData['signCount'] as int,
            userHandle: credentialData['userHandle'] != null
                ? base64Url.decode(credentialData['userHandle'] as String).toList()
                : null,
          ),
        );
      }
    }
    return credentials;
  }

  @override
  Future<void> updatePasskeySignCount({
    required List<int> credentialId,
    required int signCount,
  }) async {
    final credentialIdKey = base64Url.encode(credentialId);
    final credentialData = _data['passkeyCredential:$credentialIdKey'];
    if (credentialData == null) {
      return;
    }
    _data['passkeyCredential:$credentialIdKey'] = {
      ...credentialData,
      'signCount': signCount,
    };
  }

  @override
  Future<void> deletePasskeyCredential({
    required List<int> credentialId,
  }) async {
    final credentialIdKey = base64Url.encode(credentialId);
    final credentialData = _data['passkeyCredential:$credentialIdKey'];
    if (credentialData == null) {
      return;
    }
    final userId = credentialData['userId'] as String;
    _data['passkeyCredential:$credentialIdKey'] = null;
    // Remove from user index
    final userCredentials = (_data['passkeyCredentialsByUser:$userId']?['credentials'] as List<dynamic>?)?.cast<String>().toList() ?? <String>[];
    userCredentials.remove(credentialIdKey);
    _data['passkeyCredentialsByUser:$userId'] = {'credentials': userCredentials};
  }
}
