import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres_builder/postgres_builder.dart';
import 'package:shared_authentication_objects/shared_authentication_objects.dart';
import 'package:super_simple_authentication_server/src/create_jwt.dart';
import 'package:super_simple_authentication_server/src/create_refresh_token.dart';

/// A handler for signing in anonymously.
Handler signInAnonymouslyHandler() {
  return (context) async {
    if (context.request.method != HttpMethod.post) {
      return Response(statusCode: HttpStatus.methodNotAllowed);
    }

    final database = context.read<PostgresBuilder>();

    final userId = await database.mappedSingleQuery(
      const Insert([], into: 'users'),
      fromJson: (row) => row['id'] as String,
    );

    final jwt = await createJwt(subject: userId, isNewUser: true);

    final refreshToken = createRefreshToken();

    final sessionId = await database.mappedSingleQuery(
      Insert([
        {'user_id': userId},
      ], into: 'auth.sessions'),
      fromJson: (row) => row['id'] as String,
    );
    await database.execute(
      Insert([
        {'user_id': userId, 'token': refreshToken, 'session_id': sessionId},
      ], into: 'auth.refresh_tokens'),
    );

    return Response.json(
      body: SignInAnonymouslyResponse(token: jwt, refreshToken: refreshToken),
    );
  };
}
