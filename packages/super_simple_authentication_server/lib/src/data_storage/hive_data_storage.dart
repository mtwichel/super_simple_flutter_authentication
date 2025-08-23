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

  /// {@macro hive_data_storage}
  HiveDataStorage.autoInitialize({
    String databaseName = 'super_simple_authentication',
    String? databasePath,
    HiveCipher? encryptionKey,
  }) {
    initialize(
      databaseName: databaseName,
      databasePath: databasePath,
      encryptionCipher: encryptionKey,
    );
  }

  bool _initialized = false;
  late final Box<Map> _db;
  static const _uuid = Uuid();

  /// Initializes the database.
  Future<void> initialize({
    String databaseName = 'super_simple_authentication',
    String? databasePath,
    HiveCipher? encryptionCipher,
  }) async {
    if (_initialized) {
      return;
    }
    _db = await Hive.openBox(
      databaseName,
      path: databasePath,
      encryptionCipher: encryptionCipher,
    );

    _initialized = true;
  }

  @override
  Future<void> createOtp({
    required String identifier,
    required String channel,
    required String hashedOtp,
    required String expiresAt,
  }) {
    return _db.put('otp:$channel:$identifier', {
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
    return _db.put('refreshToken:$refreshToken', {
      'userId': userId,
      'sessionId': sessionId,
      'revoked': false,
      if (parentToken != null) 'parentToken': parentToken,
    });
  }

  @override
  Future<String> createSession(String userId) async {
    final sessionId = _uuid.v4();
    await _db.put('session:$sessionId', {
      'userId': userId,
      'refreshedAt': null,
    });
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
    await _db.put('user:$userId', {
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (hashedPassword != null) 'hashedPassword': hashedPassword,
      if (salt != null) 'salt': salt,
    });
    if (email != null) {
      await _db.put('email:$email', {'userId': userId});
    }
    if (phoneNumber != null) {
      await _db.put('phoneNumber:$phoneNumber', {'userId': userId});
    }
    return userId;
  }

  @override
  Future<String?> getOtpFor({
    required String identifier,
    required String channel,
    required String now,
  }) async {
    final otp = _db.get('otp:$channel:$identifier');
    if (otp == null) return null;
    if (DateTime.parse(
      otp['expiresAt'] as String,
    ).isBefore(DateTime.parse(now))) {
      await _db.delete('otp:$channel:$identifier');
      return null;
    }
    return otp['hashedOtp'] as String;
  }

  @override
  Future<({bool revoked, String sessionId, String userId})> getRefreshToken({
    required String refreshToken,
  }) async {
    final refreshTokenData = _db.get('refreshToken:$refreshToken');
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
    final userId = _db.get('email:$email')?['userId'] as String?;
    if (userId == null) {
      return [];
    }
    final user = _db.get('user:$userId');
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
    final userId = _db.get('phoneNumber:$phoneNumber')?['userId'] as String?;
    if (userId == null) {
      return [];
    }
    final user = _db.get('user:$userId');
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
  Future<void> revokeOtpsFor({
    required String identifier,
    required String channel,
  }) {
    return _db.delete('otp:$channel:$identifier');
  }

  @override
  Future<void> revokeRefreshToken({required String refreshToken}) async {
    final refreshTokenData = _db.get('refreshToken:$refreshToken');
    if (refreshTokenData == null) {
      return;
    }
    await _db.put('refreshToken:$refreshToken', {
      ...refreshTokenData,
      'revoked': true,
    });
  }

  @override
  Future<void> updateSession({
    required String sessionId,
    required String refreshedAt,
  }) async {
    final sessionData = _db.get('session:$sessionId');
    if (sessionData == null) {
      return;
    }
    await _db.put('session:$sessionId', {
      ...sessionData,
      'refreshedAt': refreshedAt,
    });
  }
}
