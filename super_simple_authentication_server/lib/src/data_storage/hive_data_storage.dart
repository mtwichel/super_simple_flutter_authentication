// ignore_for_file: strict_raw_type

import 'package:hive_ce/hive.dart';
import 'package:super_simple_authentication_server/src/data_storage/data_storage.dart';
import 'package:uuid/uuid.dart';

/// {@template hive_data_storage}
/// A [DataStorage] implementation that uses Hive for data storage.
/// {@endtemplate}
class HiveDataStorage implements DataStorage {
  /// {@macro hive_data_storage}
  HiveDataStorage();

  late final BoxCollection _db;
  late final CollectionBox<Map> _usersBox;
  late final CollectionBox<Map> _otpsBox;
  late final CollectionBox<Map> _refreshTokensBox;
  late final CollectionBox<Map> _sessionsBox;
  late final CollectionBox<String> _emailsBox;
  late final CollectionBox<String> _phoneNumbersBox;
  static const _uuid = Uuid();

  /// Initializes the database.
  Future<void> initialize() async {
    _db = await BoxCollection.open('super_simple_authentication', {
      'otps',
      'refresh_tokens',
      'sessions',
      'users',
      'emails',
      'phone_numbers',
    });

    _usersBox = await _db.openBox<Map>('users');
    _otpsBox = await _db.openBox<Map>('otps');
    _refreshTokensBox = await _db.openBox<Map>('refresh_tokens');
    _sessionsBox = await _db.openBox<Map>('sessions');
    _emailsBox = await _db.openBox<String>('emails');
    _phoneNumbersBox = await _db.openBox<String>('phone_numbers');
  }

  @override
  Future<void> createOtp({
    required String identifier,
    required String channel,
    required String hashedOtp,
    required String expiresAt,
  }) {
    return _otpsBox.put('$channel:$identifier', {
      'hashedOtp': hashedOtp,
      'expiresAt': expiresAt,
    });
  }

  @override
  Future<void> createRefreshToken({
    required String sessionId,
    required String refreshToken,
    required String userId,
    String? parentToken,
  }) {
    return _refreshTokensBox.put(refreshToken, {
      'userId': userId,
      'sessionId': sessionId,
      'revoked': false,
      if (parentToken != null) 'parentToken': parentToken,
    });
  }

  @override
  Future<String> createSession(String userId) async {
    final sessionId = _uuid.v4();
    await _sessionsBox.put(sessionId, {'userId': userId, 'refreshedAt': null});
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
    await _usersBox.put(userId, {
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (hashedPassword != null) 'hashedPassword': hashedPassword,
      if (salt != null) 'salt': salt,
    });
    if (email != null) {
      await _emailsBox.put(email, userId);
    }
    if (phoneNumber != null) {
      await _phoneNumbersBox.put(phoneNumber, userId);
    }
    return userId;
  }

  @override
  Future<String?> getOtpFor({
    required String identifier,
    required String channel,
    required String now,
  }) async {
    final otp = await _otpsBox.get('$channel:$identifier');
    if (otp == null) return null;
    if (DateTime.parse(
      otp['expiresAt'] as String,
    ).isBefore(DateTime.parse(now))) {
      await _otpsBox.delete('$channel:$identifier');
      return null;
    }
    return otp['hashedOtp'] as String;
  }

  @override
  Future<({bool revoked, String sessionId, String userId})> getRefreshToken({
    required String refreshToken,
  }) async {
    final refreshTokenData = await _refreshTokensBox.get(refreshToken);
    if (refreshTokenData == null) {
      return (revoked: false, sessionId: '', userId: '');
    }
    return (
      revoked: refreshTokenData['revoked'] as bool,
      sessionId: refreshTokenData['sessionId'] as String,
      userId: refreshTokenData['userId'] as String,
    );
  }

  @override
  Future<List<User>> getUsersByEmail(String email) async {
    final userId = await _emailsBox.get(email);
    if (userId == null) {
      return [];
    }
    final user = await _usersBox.get(userId);
    return [
      (
        id: userId,
        email: user?['email'] as String?,
        phoneNumber: user?['phoneNumber'] as String?,
        hashedPassword: user?['hashedPassword'] as String?,
        salt: user?['salt'] as String?,
      ),
    ];
  }

  @override
  Future<List<User>> getUsersByPhoneNumber(String phoneNumber) async {
    final userId = await _phoneNumbersBox.get(phoneNumber);
    if (userId == null) {
      return [];
    }
    final user = await _usersBox.get(userId);
    return [
      (
        id: userId,
        email: null,
        phoneNumber: user?['phoneNumber'] as String?,
        hashedPassword: user?['hashedPassword'] as String?,
        salt: user?['salt'] as String?,
      ),
    ];
  }

  @override
  Future<void> revokeOtpsFor({
    required String identifier,
    required String channel,
  }) {
    return _otpsBox.delete('$channel:$identifier');
  }

  @override
  Future<void> revokeRefreshToken({required String refreshToken}) async {
    final refreshTokenData = await _refreshTokensBox.get(refreshToken);
    if (refreshTokenData == null) {
      return;
    }
    await _refreshTokensBox.put(refreshToken, {
      ...refreshTokenData,
      'revoked': true,
    });
  }

  @override
  Future<void> updateSession({
    required String sessionId,
    required String refreshedAt,
  }) async {
    final sessionData = await _sessionsBox.get(sessionId);
    if (sessionData == null) {
      return;
    }
    await _sessionsBox.put(sessionId, {
      ...sessionData,
      'refreshedAt': refreshedAt,
    });
  }
}
