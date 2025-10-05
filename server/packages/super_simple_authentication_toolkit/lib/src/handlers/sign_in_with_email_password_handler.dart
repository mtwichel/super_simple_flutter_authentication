import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:super_simple_authentication_toolkit/super_simple_authentication_toolkit.dart';

/// A handler for signing in with an email and password.
Handler signInWithEmailPasswordHandler() {
  return (context) async {
    if (context.request.method != HttpMethod.post) {
      return Response(statusCode: HttpStatus.methodNotAllowed);
    }
    final {'email': String email, 'password': String password} = await context
        .request
        .map();

    final dataStorage = context.read<DataStorage>();
    final result = await dataStorage.getUsersByEmail(email);

    if (result.isEmpty) {
      return Response.json(
        body: SignInResponse(error: 'User not found'),
      );
    }

    if (result.isEmpty) {
      return Response.json(
        body: SignInResponse(error: 'User not found'),
      );
    }

    final userId = result.first.id;

    final hashedPassword = result.first.hashedPassword;
    final salt = result.first.salt;

    if (hashedPassword == null || salt == null) {
      return Response.json(
        body: SignInResponse(error: 'Invalid credentials'),
      );
    }

    final storedPassword = base64.decode(hashedPassword);
    final storedSalt = base64.decode(salt);

    final (hash: computedHash, salt: _) = await calculatePasswordHash(
      password,
      salt: storedSalt,
    );

    if (computedHash.length != storedPassword.length) {
      return Response.json(
        body: SignInResponse(error: 'Invalid credentials'),
      );
    }

    for (var i = 0; i < computedHash.length; i++) {
      if (computedHash[i] != storedPassword[i]) {
        return Response.json(
          body: SignInResponse(error: 'Invalid credentials'),
        );
      }
    }
    final jwt = await createJwt(
      subject: userId,
      isNewUser: false,
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
      body: SignInResponse(
        token: jwt,
        refreshToken: refreshToken,
      ),
    );
  };
}
