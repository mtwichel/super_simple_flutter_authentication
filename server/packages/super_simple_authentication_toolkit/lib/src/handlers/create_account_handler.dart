import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:super_simple_authentication_toolkit/src/data_storage/data_storage.dart';
import 'package:super_simple_authentication_toolkit/src/util/util.dart';

/// A handler for creating a new account.
Handler createAccountHandler() {
  return (context) async {
    if (context.request.method != HttpMethod.post) {
      return Response(statusCode: HttpStatus.methodNotAllowed);
    }
    final {'email': String email, 'password': String password} = await context
        .request
        .map();

    final dataStorage = context.read<DataStorage>();

    final hashedPassword = await calculatePasswordHash(password);

    final userId = await dataStorage.createUser(
      email: email,
      hashedPassword: base64.encode(hashedPassword.hash),
      salt: base64.encode(hashedPassword.salt),
    );

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

    return Response.json(body: {'token': jwt, 'refreshToken': refreshToken});
  };
}
