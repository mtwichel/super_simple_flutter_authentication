import 'package:postgres_builder/postgres_builder.dart';
import 'package:super_simple_authentication_server/src/data_storage/data_storage.dart';

/// {@template postgres_data_storage}
/// A data storage implementation for the authentication server using
/// PostgreSQL.
/// {@endtemplate}
class PostgresDataStorage extends DataStorage {
  /// {@macro postgres_data_storage}
  PostgresDataStorage(this._database);

  final PostgresBuilder _database;

  @override
  Future<void> createRefreshToken({
    required String sessionId,
    required String refreshToken,
    required String userId,
    String? parentToken,
  }) {
    return _database.execute(
      Insert([
        {
          'user_id': userId,
          'token': refreshToken,
          'session_id': sessionId,
          if (parentToken != null) 'parent_token': parentToken,
        },
      ], into: 'auth.refresh_tokens'),
    );
  }

  @override
  Future<String> createSession(String userId) {
    return _database.mappedSingleQuery(
      Insert([
        {'user_id': userId},
      ], into: 'auth.sessions'),
      fromJson: (row) => row['id'] as String,
    );
  }

  @override
  Future<String> createUser({
    String? email,
    String? phoneNumber,
    String? hashedPassword,
    String? salt,
  }) {
    return _database.mappedSingleQuery(
      Insert([
        {
          if (email != null) 'email': email,
          if (phoneNumber != null) 'phone_number': phoneNumber,
          if (hashedPassword != null) 'password': hashedPassword,
          if (salt != null) 'salt': salt,
        },
      ], into: 'users'),
      fromJson: (row) => row['id'] as String,
    );
  }

  @override
  Future<({bool revoked, String sessionId, String userId})> getRefreshToken({
    required String refreshToken,
  }) {
    return _database.mappedSingleQuery(
      Select(
        [
          const Column('user_id'),
          const Column('session_id'),
          const Column('revoked'),
        ],
        from: 'auth.refresh_tokens',
        where: const Column('token').equals(refreshToken),
      ),
      fromJson:
          (row) => (
            userId: row['user_id'] as String,
            sessionId: row['session_id'] as String,
            revoked: row['revoked'] as bool,
          ),
    );
  }

  @override
  Future<void> revokeRefreshToken({required String refreshToken}) {
    return _database.execute(
      Update(
        {'revoked': true},
        from: 'auth.refresh_tokens',
        where: const Column('token').equals(refreshToken),
      ),
    );
  }

  @override
  Future<void> updateSession({
    required String sessionId,
    required String refreshedAt,
  }) {
    return _database.execute(
      Update(
        {'refreshed_at': refreshedAt},
        from: 'auth.sessions',
        where: const Column('id').equals(sessionId),
      ),
    );
  }

  @override
  Future<void> revokeOtpsFor({
    required String identifier,
    required String channel,
  }) {
    return _database.execute(
      Update(
        {'revoked': true},
        from: 'auth.otps',
        where:
            const Column('identifier').equals(identifier) &
            const Column('channel').equals(channel),
      ),
    );
  }

  @override
  Future<void> createOtp({
    required String identifier,
    required String channel,
    required String hashedOtp,
    required String expiresAt,
  }) {
    return _database.execute(
      Insert([
        {
          'identifier': identifier,
          'otp': hashedOtp,
          'channel': channel,
          'expires_at': expiresAt,
        },
      ], into: 'auth.otps'),
    );
  }

  @override
  Future<List<User>> getUsersByEmail(String email) {
    return _database.mappedQuery(
      Select(
        [
          const Column('id'),
          const Column('email'),
          const Column('password'),
          const Column('salt'),
          const Column('phone_number'),
        ],
        from: 'users',
        where: const Column('email').equals(email),
      ),
      fromJson:
          (row) => (
            id: row['id'] as String,
            email: row['email'] as String,
            hashedPassword: row['password'] as String,
            salt: row['salt'] as String,
            phoneNumber: null,
          ),
    );
  }

  @override
  Future<List<User>> getUsersByPhoneNumber(String phoneNumber) {
    return _database.mappedQuery(
      Select(
        [
          const Column('id'),
          const Column('phone_number'),
          const Column('password'),
          const Column('salt'),
          const Column('email'),
        ],
        from: 'users',
        where: const Column('phone_number').equals(phoneNumber),
      ),
      fromJson:
          (row) => (
            id: row['id'] as String,
            email: null,
            phoneNumber: row['phone_number'] as String,
            hashedPassword: row['password'] as String,
            salt: row['salt'] as String,
          ),
    );
  }

  @override
  Future<String?> getOtpFor({
    required String identifier,
    required String channel,
    required String now,
  }) async {
    final rows = await _database.mappedQuery(
      Select(
        [const Column('id'), const Column('otp')],
        from: 'auth.otps',
        where:
            const Column('identifier').equals(identifier) &
            const Column('channel').equals(channel) &
            const Column('expires_at').greaterThan(now) &
            const Not(Column('revoked')),
      ),
      fromJson: (row) => row['otp'] as String,
    );
    if (rows.isEmpty) {
      return null;
    }
    if (rows.length > 1) {
      return null;
    }
    return rows.first;
  }
}
