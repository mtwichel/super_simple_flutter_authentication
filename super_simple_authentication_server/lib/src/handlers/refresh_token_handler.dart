import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres_builder/postgres_builder.dart';
import 'package:shared_authentication_objects/shared_authentication_objects.dart';
import 'package:super_simple_authentication_server/src/create_jwt.dart';
import 'package:super_simple_authentication_server/src/create_refresh_token.dart';
import 'package:super_simple_authentication_server/src/utilities.dart';

/// A handler for refreshing a token.
Handler refreshTokenHandler() {
  return (context) async {
    if (context.request.method != HttpMethod.post) {
      return Response(statusCode: HttpStatus.methodNotAllowed);
    }
    final requestBody = await context.request.parse(
      RefreshTokenRequest.fromJson,
    );

    final database = context.read<PostgresBuilder>();

    final (:userId, :sessionId, :revoked) = await database.mappedSingleQuery(
      Select(
        [
          const Column('user_id'),
          const Column('session_id'),
          const Column('revoked'),
        ],
        from: 'auth.refresh_tokens',
        where: const Column('token').equals(requestBody.refreshToken),
      ),
      fromJson:
          (row) => (
            userId: row['user_id'] as String,
            sessionId: row['session_id'] as String,
            revoked: row['revoked'] as bool,
          ),
    );

    if (revoked) {
      return Response.json(
        body: const RefreshTokenResponse(error: RefreshTokenError.revoked),
      );
    }
    await database.execute(
      Update(
        {'revoked': true},
        from: 'auth.refresh_tokens',
        where: const Column('token').equals(requestBody.refreshToken),
      ),
    );
    await database.execute(
      Update(
        {'refreshed_at': DateTime.now().toUtc().toIso8601String()},
        from: 'auth.sessions',
        where: const Column('id').equals(sessionId),
      ),
    );

    final jwt = await createJwt(subject: userId, isNewUser: false);

    final newRefreshToken = createRefreshToken();

    await database.execute(
      Insert([
        {
          'user_id': userId,
          'token': newRefreshToken,
          'session_id': sessionId,
          'parent_token': requestBody.refreshToken,
        },
      ], into: 'auth.refresh_tokens'),
    );
    return Response.json(
      body: RefreshTokenResponse(token: jwt, refreshToken: newRefreshToken),
    );
  };
}
