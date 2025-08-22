import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:shared_authentication_objects/shared_authentication_objects.dart';
import 'package:super_simple_authentication_server/src/data_storage/data_storage.dart';
import 'package:super_simple_authentication_server/src/util/util.dart';

/// A handler for creating a new account.
Handler createAccountHandler() {
  return (context) async {
    if (context.request.method != HttpMethod.post) {
      return Response(statusCode: HttpStatus.methodNotAllowed);
    }
    final requestBody = await context.request.parse(
      CreateAccountWithEmailAndPasswordRequest.fromJson,
    );

    final dataStorage = context.read<DataStorage>();

    final hashedPassword = await calculatePasswordHash(requestBody.password);

    final userId = await dataStorage.createUser(
      email: requestBody.email,
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

    return Response.json(
      body: CreateAccountWithEmailAndPasswordResponse(
        token: jwt,
        refreshToken: refreshToken,
      ),
    );
  };
}
