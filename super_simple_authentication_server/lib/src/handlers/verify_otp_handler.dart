import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:shared_authentication_objects/shared_authentication_objects.dart';
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
    final requestBody = await context.request.parse(VerifyOtpRequest.fromJson);

    final dataStorage = context.read<DataStorage>();
    final now = context.read<Now>();
    final otp = await dataStorage.getOtpFor(
      identifier: requestBody.identifier,
      channel: requestBody.type.name,
      now: now.toIso8601String(),
    );

    if (otp == null) {
      return Response.json(
        body: const VerifyOtpResponse(
          token: null,
          error: SignInError.otpInvalid,
          refreshToken: null,
        ),
      );
    }

    final hashedRequestOtp = await hashOtp(requestBody.otp);

    if (hashedRequestOtp != otp) {
      return Response.json(
        body: const VerifyOtpResponse(
          token: null,
          error: SignInError.otpInvalid,
          refreshToken: null,
        ),
      );
    }

    await dataStorage.revokeOtpsFor(
      identifier: requestBody.identifier,
      channel: requestBody.type.name,
    );

    final String userId;
    final users =
        requestBody.type == OtpType.email
            ? await dataStorage.getUsersByEmail(requestBody.identifier)
            : await dataStorage.getUsersByPhoneNumber(requestBody.identifier);
    if (users.length > 1) {
      return Response.json(
        body: const VerifyOtpResponse(
          token: null,
          error: SignInError.unknown,
          refreshToken: null,
        ),
      );
    }
    final isNewUser = users.isEmpty;
    if (isNewUser) {
      userId = await dataStorage.createUser(
        email:
            requestBody.type == OtpType.email ? requestBody.identifier : null,
        phoneNumber:
            requestBody.type == OtpType.phone ? requestBody.identifier : null,
      );

      await onNewUser?.call(
        userId: userId,
        email:
            requestBody.type == OtpType.email ? requestBody.identifier : null,
        phoneNumber:
            requestBody.type == OtpType.phone ? requestBody.identifier : null,
      );
    } else {
      userId = users.first.id;
    }

    final token = await createJwt(subject: userId, isNewUser: isNewUser);
    final refreshToken = createRefreshToken();

    final sessionId = await dataStorage.createSession(userId);
    await dataStorage.createRefreshToken(
      sessionId: sessionId,
      refreshToken: refreshToken,
      userId: userId,
    );

    return Response.json(
      body: VerifyOtpResponse(
        token: token,
        error: null,
        refreshToken: refreshToken,
      ),
    );
  };
}
