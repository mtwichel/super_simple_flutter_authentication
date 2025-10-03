import 'package:postgres/postgres.dart';

/// Initializes the database schema for Super Simple Authentication.
///
/// Creates the auth schema, tables, and indexes required for the
/// authentication system to function properly.
Future<void> initializeDatabase(Connection connection) async {
  // Create auth schema
  await connection.execute(
    'CREATE SCHEMA IF NOT EXISTS auth',
  );

  // Create users table
  await connection.execute('''
    CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email VARCHAR(255) UNIQUE,
        phone_number VARCHAR(50) UNIQUE,
        password TEXT,
        salt TEXT,
        created_at TIMESTAMP DEFAULT NOW()
    )
  ''');

  // Create sessions table
  await connection.execute('''
    CREATE TABLE IF NOT EXISTS auth.sessions (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        refreshed_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT NOW()
    )
  ''');

  // Create refresh tokens table
  await connection.execute('''
    CREATE TABLE IF NOT EXISTS auth.refresh_tokens (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        session_id UUID NOT NULL REFERENCES auth.sessions(id) ON DELETE CASCADE,
        token TEXT NOT NULL UNIQUE,
        parent_token TEXT,
        revoked BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT NOW()
    )
  ''');

  // Create OTPs table
  await connection.execute('''
    CREATE TABLE IF NOT EXISTS auth.otps (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        identifier VARCHAR(255) NOT NULL,
        channel VARCHAR(50) NOT NULL,
        otp TEXT NOT NULL,
        expires_at TIMESTAMP NOT NULL,
        revoked BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT NOW()
    )
  ''');

  // Create indexes for better performance
  await connection.execute(
    'CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)',
  );

  await connection.execute(
    '''CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone_number)''',
  );

  await connection.execute(
    '''CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token ON auth.refresh_tokens(token)''',
  );

  await connection.execute(
    '''CREATE INDEX IF NOT EXISTS idx_otps_identifier_channel ON auth.otps(identifier, channel)''',
  );
}
