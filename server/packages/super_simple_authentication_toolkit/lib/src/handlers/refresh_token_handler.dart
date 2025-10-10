import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:super_simple_authentication_toolkit/super_simple_authentication_toolkit.dart';

/// A handler for refreshing a token.
Handler refreshTokenHandler() {
  return (context) async {
    if (context.request.method != HttpMethod.post) {
      return Response(statusCode: HttpStatus.methodNotAllowed);
    }
    final {'refreshToken': String refreshToken} = await context.request.map();

    final dataStorage = context.read<DataStorage>();

    final (:userId, :sessionId, :revoked) = await dataStorage.getRefreshToken(
      refreshToken: refreshToken,
    );

    if (revoked) {
      return Response.json(
        body: SignInResponse(error: SignInError.refreshTokenRevoked),
      );
    }

    await dataStorage.revokeRefreshToken(refreshToken: refreshToken);

    await dataStorage.updateSession(
      sessionId: sessionId,
      refreshedAt: DateTime.now().toIso8601String(),
    );

    final jwt = await createJwt(
      subject: userId,
      isNewUser: false,
      environment: context.read<Environment>(),
    );

    final newRefreshToken = createRefreshToken();

    await dataStorage.createRefreshToken(
      sessionId: sessionId,
      refreshToken: newRefreshToken,
      userId: userId,
      parentToken: refreshToken,
    );

    return Response.json(
      body: SignInResponse(
        token: jwt,
        refreshToken: newRefreshToken,
      ),
    );
  };
}
