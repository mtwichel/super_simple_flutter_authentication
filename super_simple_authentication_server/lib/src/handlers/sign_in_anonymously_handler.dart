import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:shared_authentication_objects/shared_authentication_objects.dart';
import 'package:super_simple_authentication_server/src/data_storage/data_storage.dart';
import 'package:super_simple_authentication_server/src/util/util.dart';

/// A handler for signing in anonymously.
Handler signInAnonymouslyHandler() {
  return (context) async {
    if (context.request.method != HttpMethod.post) {
      return Response(statusCode: HttpStatus.methodNotAllowed);
    }

    final dataStorage = context.read<DataStorage>();

    final userId = await dataStorage.createUser();

    final jwt = await createJwt(
      subject: userId,
      isNewUser: true,
      environment: context.read<Environment>(),
    );

    final refreshToken = createRefreshToken();
    final sessionId = await dataStorage.createSession(userId);
    await dataStorage.createRefreshToken(
      sessionId: sessionId,
      refreshToken: refreshToken,
      userId: userId,
    );

    return Response.json(
      body: SignInAnonymouslyResponse(token: jwt, refreshToken: refreshToken),
    );
  };
}
