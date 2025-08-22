import 'package:super_simple_authentication_server/src/data_storage/data_storage.dart';
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
    _data['$identifier:$channel'] = {'otp': hashedOtp, 'expiresAt': expiresAt};
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
    final key = '$identifier:$channel';
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
    final key = '$identifier:$channel';
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
}
