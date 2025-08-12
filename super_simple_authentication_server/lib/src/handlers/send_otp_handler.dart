import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_utilities/dart_frog_utilities.dart';
import 'package:postgres_builder/postgres_builder.dart';
import 'package:shared_authentication_objects/shared_authentication_objects.dart';
import 'package:super_simple_authentication_server/src/create_otp.dart';
import 'package:super_simple_authentication_server/src/hash_otp.dart';
import 'package:super_simple_authentication_server/super_simple_authentication_server.dart';

/// The duration the OTP will expire in.
const otpExpiration = Duration(minutes: 10);

/// A handler for sending an OTP.
Handler sendOtpHandler({bool debugOtps = false}) {
  return (context) async {
    if (context.request.method != HttpMethod.post) {
      return Response(statusCode: HttpStatus.methodNotAllowed);
    }
    final requestBody = await context.request.parse(SendOtpRequest.fromJson);

    final database = context.read<PostgresBuilder>();
    await database.execute(
      Update(
        {'revoked': true},
        where:
            const Column('identifier').equals(requestBody.identifier) &
            const Column('channel').equals(requestBody.type.name),
        from: 'auth.otps',
      ),
    );

    final testingEmail = context.environment['TESTING_EMAIL'];
    final testingPhoneNumber = context.environment['TESTING_PHONE_NUMBER'];
    final testingOtp = context.environment['TESTING_OTP'];

    final usingTestOtp =
        (requestBody.identifier == testingEmail ||
            requestBody.identifier == testingPhoneNumber) &&
        testingOtp != null;

    final otp = usingTestOtp ? testingOtp : createOtp();

    final hashedOtp = await hashOtp(otp);
    final now = context.read<Now>();
    final expiresAt = now.add(otpExpiration);
    await database.execute(
      Insert([
        {
          'identifier': requestBody.identifier,
          'otp': hashedOtp,
          'channel': requestBody.type.name,
          'expires_at': expiresAt,
        },
      ], into: 'auth.otps'),
    );

    if (debugOtps) {
      // ignore: avoid_print
      print('OTP: $otp');
    } else if (!usingTestOtp) {
      switch (requestBody.type) {
        case OtpType.email:
          final sendgrid = context.read<Sendgrid>();
          await sendgrid.sendEmail(
            to: requestBody.identifier,
            subject: 'Otp for Clubhaus',
            body: 'Your OTP is $otp',
            from: 'noreply@joinclubhaus.com',
          );
        case OtpType.phone:
          final smsProvider = context.read<SmsProvider>();
          await smsProvider.sendSms(
            requestBody.identifier,
            'Your Clubhaus verification code is $otp',
          );
      }
    }

    return Response.json(
      body: SendOtpResponse(expiresAt: expiresAt, expiresIn: otpExpiration),
    );
  };
}
