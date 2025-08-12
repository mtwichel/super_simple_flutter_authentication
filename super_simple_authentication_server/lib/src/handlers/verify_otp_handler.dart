import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_utilities/dart_frog_utilities.dart';
import 'package:postgres_builder/postgres_builder.dart';
import 'package:shared_authentication_objects/shared_authentication_objects.dart';
import 'package:super_simple_authentication_server/src/create_jwt.dart';
import 'package:super_simple_authentication_server/src/create_refresh_token.dart';
import 'package:super_simple_authentication_server/src/hash_otp.dart';

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

    final database = context.read<PostgresBuilder>();
    final now = context.read<Now>();
    final otpResponse = await database.mappedQuery(
      Select(
        [const Column('id'), const Column('otp')],
        from: 'auth.otps',
        where:
            const Column('identifier').equals(requestBody.identifier) &
            const Column('channel').equals(requestBody.type.name) &
            const Column('expires_at').greaterThan(now) &
            const Not(Column('revoked')),
      ),
      fromJson: (row) => (id: row['id'] as int, otp: row['otp'] as String),
    );

    if (otpResponse.isEmpty || otpResponse.length > 1) {
      return Response.json(
        body: const VerifyOtpResponse(
          token: null,
          error: SignInError.otpInvalid,
          refreshToken: null,
        ),
      );
    }

    final otp = otpResponse.first;
    final hashedRequestOtp = await hashOtp(requestBody.otp);

    if (hashedRequestOtp != otp.otp) {
      return Response.json(
        body: const VerifyOtpResponse(
          token: null,
          error: SignInError.otpInvalid,
          refreshToken: null,
        ),
      );
    }

    await database.execute(
      Update(
        {'revoked': true},
        where: const Column('id').equals(otp.id),
        from: 'auth.otps',
      ),
    );

    final String userId;
    final users = await database.mappedQuery(
      Select(
        [const Column('id')],
        from: 'users',
        where:
            requestBody.type == OtpType.email
                ? const Column('email').equals(requestBody.identifier)
                : const Column('phone_number').equals(requestBody.identifier),
      ),
      fromJson: (row) => row['id'] as String,
    );
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
      userId = await database.mappedSingleQuery(
        Insert([
          {
            if (requestBody.type == OtpType.email)
              'email': requestBody.identifier,
            if (requestBody.type == OtpType.phone)
              'phone_number': requestBody.identifier,
          },
        ], into: 'users'),
        fromJson: (row) => row['id'] as String,
      );

      await onNewUser?.call(
        userId: userId,
        email:
            requestBody.type == OtpType.email ? requestBody.identifier : null,
        phoneNumber:
            requestBody.type == OtpType.phone ? requestBody.identifier : null,
      );
    } else {
      userId = users.first;
    }

    final token = await createJwt(subject: userId, isNewUser: isNewUser);
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
      body: VerifyOtpResponse(
        token: token,
        error: null,
        refreshToken: refreshToken,
      ),
    );
  };
}
