import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:shared_authentication_objects/shared_authentication_objects.dart';
import 'package:super_simple_authentication_server/src/data_storage/data_storage.dart';
import 'package:super_simple_authentication_server/src/util/util.dart';

/// A handler for signing in with an email and password.
Handler signInWithEmailPasswordHandler() {
  return (context) async {
    if (context.request.method != HttpMethod.post) {
      return Response(statusCode: HttpStatus.methodNotAllowed);
    }
    final requestBody = await context.request.parse(
      SignInWithEmailAndPasswordRequest.fromJson,
    );

    final dataStorage = context.read<DataStorage>();
    final result = await dataStorage.getUsersByEmail(requestBody.email);

    if (result.isEmpty) {
      return Response.json(
        body: const SignInWithEmailAndPasswordResponse(
          error: SignInError.userNotFound,
        ),
      );
    }

    if (result.isEmpty) {
      return Response.json(
        body: const SignInWithEmailAndPasswordResponse(
          error: SignInError.userNotFound,
        ),
      );
    }

    final userId = result.first.id;

    final hashedPassword = result.first.hashedPassword;
    final salt = result.first.salt;

    if (hashedPassword == null || salt == null) {
      return Response.json(
        body: const SignInWithEmailAndPasswordResponse(
          error: SignInError.invalidCredentials,
        ),
      );
    }

    final storedPassword = base64.decode(hashedPassword);
    final storedSalt = base64.decode(salt);

    final (hash: computedHash, salt: _) = await calculatePasswordHash(
      requestBody.password,
      salt: storedSalt,
    );

    if (computedHash.length != storedPassword.length) {
      return Response.json(
        body: const SignInWithEmailAndPasswordResponse(
          error: SignInError.invalidCredentials,
        ),
      );
    }

    for (var i = 0; i < computedHash.length; i++) {
      if (computedHash[i] != storedPassword[i]) {
        return Response.json(
          body: const SignInWithEmailAndPasswordResponse(
            error: SignInError.invalidCredentials,
          ),
        );
      }
    }
    final jwt = await createJwt(subject: userId, isNewUser: false);

    final refreshToken = createRefreshToken();

    final sessionId = await dataStorage.createSession(userId);
    await dataStorage.createRefreshToken(
      sessionId: sessionId,
      refreshToken: refreshToken,
      userId: userId,
    );

    return Response.json(
      body: SignInWithEmailAndPasswordResponse(
        token: jwt,
        refreshToken: refreshToken,
      ),
    );
  };
}
