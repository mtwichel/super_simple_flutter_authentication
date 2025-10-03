import 'package:super_simple_authentication_postgres_data_storage/super_simple_authentication_postgres_data_storage.dart';
import 'package:super_simple_authentication_toolkit/super_simple_authentication_toolkit.dart';

/// {@template postgres_data_storage}
/// A data storage implementation for the authentication server using
/// PostgreSQL.
/// {@endtemplate}
class PostgresDataStorage extends DataStorage {
  /// {@macro postgres_data_storage}
  PostgresDataStorage();

  /// {@macro postgres_data_storage}
  PostgresDataStorage.fromConnection(this._connection);

  late final Connection _connection;

  /// Initializes the data storage with a PostgresBuilder instance.
  Future<void> initialize({
    required Endpoint endpoint,
    ConnectionSettings? settings,
    bool shouldInitializeDatabase = false,
    SchemaDefinition schemaDefinition = const SchemaDefinition(),
  }) async {
    _connection = await Connection.open(
      endpoint,
      settings: settings,
    );
    if (shouldInitializeDatabase) {
      await initializeDatabase(_connection);
    }
  }

  @override
  Future<void> createRefreshToken({
    required String sessionId,
    required String refreshToken,
    required String userId,
    String? parentToken,
  }) async {
    await _connection.execute(
      Sql.named('''
        INSERT INTO auth.refresh_tokens (user_id, token, session_id, parent_token)
        VALUES (@userId, @refreshToken, @sessionId, @parentToken)
      '''),
      parameters: {
        'userId': userId,
        'refreshToken': refreshToken,
        'sessionId': sessionId,
        'parentToken': parentToken,
      },
    );
  }

  @override
  Future<String> createSession(String userId) async {
    final result = await _connection.execute(
      Sql.named('''
        INSERT INTO auth.sessions (user_id)
        VALUES (@userId)
        RETURNING id
      '''),
      parameters: {
        'userId': userId,
      },
    );
    return result.first.first! as String;
  }

  @override
  Future<String> createUser({
    String? email,
    String? phoneNumber,
    String? hashedPassword,
    String? salt,
  }) async {
    final result = await _connection.execute(
      Sql.named('''
        INSERT INTO users (email, phone_number, password, salt)
        VALUES (@email, @phoneNumber, @hashedPassword, @salt)
        RETURNING id
      '''),
      parameters: {
        'email': email,
        'phoneNumber': phoneNumber,
        'hashedPassword': hashedPassword,
        'salt': salt,
      },
    );
    return result.first.first! as String;
  }

  @override
  Future<({bool revoked, String sessionId, String userId})> getRefreshToken({
    required String refreshToken,
  }) async {
    final result = await _connection.execute(
      Sql.named('''
        SELECT user_id, session_id, revoked
        FROM auth.refresh_tokens
        WHERE token = @refreshToken
      '''),
      parameters: {
        'refreshToken': refreshToken,
      },
    );
    final row = result.first;
    return (
      userId: row[0]! as String,
      sessionId: row[1]! as String,
      revoked: row[2]! as bool,
    );
  }

  @override
  Future<void> revokeRefreshToken({required String refreshToken}) async {
    await _connection.execute(
      Sql.named('''
        UPDATE auth.refresh_tokens
        SET revoked = true
        WHERE token = @refreshToken
      '''),
      parameters: {
        'refreshToken': refreshToken,
      },
    );
  }

  @override
  Future<void> updateSession({
    required String sessionId,
    required String refreshedAt,
  }) async {
    await _connection.execute(
      Sql.named('''
        UPDATE auth.sessions
        SET refreshed_at = @refreshedAt
        WHERE id = @sessionId
      '''),
      parameters: {
        'sessionId': sessionId,
        'refreshedAt': refreshedAt,
      },
    );
  }

  @override
  Future<void> revokeOtpsFor({
    required String identifier,
    required String channel,
  }) async {
    await _connection.execute(
      Sql.named('''
        UPDATE auth.otps
        SET revoked = true
        WHERE identifier = @identifier AND channel = @channel
      '''),
      parameters: {
        'identifier': identifier,
        'channel': channel,
      },
    );
  }

  @override
  Future<void> createOtp({
    required String identifier,
    required String channel,
    required String hashedOtp,
    required String expiresAt,
  }) async {
    await _connection.execute(
      Sql.named('''
        INSERT INTO auth.otps (identifier, otp, channel, expires_at)
        VALUES (@identifier, @hashedOtp, @channel, @expiresAt)
      '''),
      parameters: {
        'identifier': identifier,
        'hashedOtp': hashedOtp,
        'channel': channel,
        'expiresAt': expiresAt,
      },
    );
  }

  @override
  Future<List<User>> getUsersByEmail(String email) async {
    final result = await _connection.execute(
      Sql.named('''
        SELECT id, email, password, salt, phone_number
        FROM users
        WHERE email = @email
      '''),
      parameters: {
        'email': email,
      },
    );
    return result
        .map(
          (row) => (
            id: row[0]! as String,
            email: row[1]! as String,
            hashedPassword: row[2]! as String,
            salt: row[3]! as String,
            phoneNumber: null,
          ),
        )
        .toList();
  }

  @override
  Future<List<User>> getUsersByPhoneNumber(String phoneNumber) async {
    final result = await _connection.execute(
      Sql.named('''
        SELECT id, phone_number, password, salt, email
        FROM users
        WHERE phone_number = @phoneNumber
      '''),
      parameters: {
        'phoneNumber': phoneNumber,
      },
    );
    return result
        .map(
          (row) => (
            id: row[0]! as String,
            email: null,
            phoneNumber: row[1]! as String,
            hashedPassword: row[2]! as String,
            salt: row[3]! as String,
          ),
        )
        .toList();
  }

  @override
  Future<String?> getOtpFor({
    required String identifier,
    required String channel,
    required String now,
  }) async {
    final result = await _connection.execute(
      Sql.named('''
        SELECT id, otp
        FROM auth.otps
        WHERE identifier = @identifier 
          AND channel = @channel 
          AND expires_at > @now 
          AND NOT revoked
      '''),
      parameters: {
        'identifier': identifier,
        'channel': channel,
        'now': now,
      },
    );
    if (result.isEmpty) {
      return null;
    }
    if (result.length > 1) {
      return null;
    }
    return result.first[1]! as String;
  }
}
