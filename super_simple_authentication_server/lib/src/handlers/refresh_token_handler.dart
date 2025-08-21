import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:shared_authentication_objects/shared_authentication_objects.dart';
import 'package:super_simple_authentication_server/src/data_storage/data_storage.dart';
import 'package:super_simple_authentication_server/src/util/util.dart';

/// A handler for refreshing a token.
Handler refreshTokenHandler() {
  return (context) async {
    if (context.request.method != HttpMethod.post) {
      return Response(statusCode: HttpStatus.methodNotAllowed);
    }
    final requestBody = await context.request.parse(
      RefreshTokenRequest.fromJson,
    );

    final dataStorage = context.read<DataStorage>();

    final (:userId, :sessionId, :revoked) = await dataStorage.getRefreshToken(
      refreshToken: requestBody.refreshToken,
    );

    if (revoked) {
      return Response.json(
        body: const RefreshTokenResponse(error: RefreshTokenError.revoked),
      );
    }

    await dataStorage.revokeRefreshToken(
      refreshToken: requestBody.refreshToken,
    );

    await dataStorage.updateSession(
      sessionId: sessionId,
      refreshedAt: DateTime.now().toIso8601String(),
    );

    final jwt = await createJwt(subject: userId, isNewUser: false);

    final newRefreshToken = createRefreshToken();

    await dataStorage.createRefreshToken(
      sessionId: sessionId,
      refreshToken: newRefreshToken,
      userId: userId,
      parentToken: requestBody.refreshToken,
    );

    return Response.json(
      body: RefreshTokenResponse(token: jwt, refreshToken: newRefreshToken),
    );
  };
}
