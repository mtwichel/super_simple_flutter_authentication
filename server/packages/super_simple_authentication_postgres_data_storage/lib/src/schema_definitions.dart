/// {@template schema_definition}
/// A definition for a schema for the authentication server database.
/// {@endtemplate}
class SchemaDefinition {
  /// {@macro schema_definition}
  const SchemaDefinition({
    this.refreshTokensTableDefinition = const RefreshTokensTableDefinition(),
  });

  /// The definition for the refresh tokens table.
  final RefreshTokensTableDefinition refreshTokensTableDefinition;
}

/// {@template refresh_tokens_table_definition}
/// A definition for the refresh tokens table.
/// {@endtemplate}
class RefreshTokensTableDefinition {
  /// {@macro refresh_tokens_table_definition}
  const RefreshTokensTableDefinition({
    this.schemaName,
    this.tableName = 'refresh_tokens',
    this.userIdColumn = 'user_id',
    this.sessionIdColumn = 'session_id',
    this.revokedColumn = 'revoked',
    this.createdAtColumn = 'created_at',
    this.expiresAtColumn = 'expires_at',
  });

  /// The name of the table.
  final String tableName;

  /// The name of the schema this table is in, if any.
  final String? schemaName;

  /// The name of the user ID column.
  final String userIdColumn;

  /// The name of the session ID column.
  final String sessionIdColumn;

  /// The name of the revoked column.
  final String revokedColumn;

  /// The name of the created at column.
  final String createdAtColumn;

  /// The name of the expires at column.
  final String expiresAtColumn;
}
