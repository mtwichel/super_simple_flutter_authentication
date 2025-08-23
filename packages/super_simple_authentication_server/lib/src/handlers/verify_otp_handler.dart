import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:super_simple_authentication_server/src/data_storage/data_storage.dart';
import 'package:super_simple_authentication_server/src/util/util.dart';

/// A handler for verifying an OTP.
Handler verifyOtpHandler({
  Future<void> Function({
    required String userId,
    String? email,
    String? phoneNumber,
  })?
  onNewUser,
}) {
  return (context) async {
    if (context.request.method != HttpMethod.post) {
      return Response(statusCode: HttpStatus.methodNotAllowed);
    }
    final {
      'identifier': String identifier,
      'type': String type,
      'otp': String otp,
    } = await context.request.map();

    final dataStorage = context.read<DataStorage>();
    final now = context.read<Now>();
    final expectedOtp = await dataStorage.getOtpFor(
      identifier: identifier,
      channel: type,
      now: now.toIso8601String(),
    );

    final hashedRequestOtp = await hashOtp(otp);

    if (hashedRequestOtp != expectedOtp) {
      return Response.json(body: {'error': 'OTP invalid'});
    }

    await dataStorage.revokeOtpsFor(identifier: identifier, channel: type);

    final String userId;
    final users =
        type == 'email'
            ? await dataStorage.getUsersByEmail(identifier)
            : await dataStorage.getUsersByPhoneNumber(identifier);
    if (users.length > 1) {
      return Response.json(body: {'error': 'Unknown error'});
    }
    final isNewUser = users.isEmpty;
    if (isNewUser) {
      userId = await dataStorage.createUser(
        email: type == 'email' ? identifier : null,
        phoneNumber: type == 'phone' ? identifier : null,
      );

      await onNewUser?.call(
        userId: userId,
        email: type == 'email' ? identifier : null,
        phoneNumber: type == 'phone' ? identifier : null,
      );
    } else {
      userId = users.first.id;
    }

    final token = await createJwt(
      subject: userId,
      isNewUser: isNewUser,
      environment: context.read<Environment>(),
    );
    final refreshToken = createRefreshToken();

    final sessionId = await dataStorage.createSession(userId);
    await dataStorage.createRefreshToken(
      sessionId: sessionId,
      refreshToken: refreshToken,
      userId: userId,
    );

    return Response.json(body: {'token': token, 'refreshToken': refreshToken});
  };
}
