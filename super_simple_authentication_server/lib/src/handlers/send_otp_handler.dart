import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres_builder/postgres_builder.dart';
import 'package:shared_authentication_objects/shared_authentication_objects.dart';
import 'package:super_simple_authentication_server/src/create_otp.dart';
import 'package:super_simple_authentication_server/src/hash_otp.dart';
import 'package:super_simple_authentication_server/src/utilities.dart';
import 'package:super_simple_authentication_server/super_simple_authentication_server.dart';

/// The duration the OTP will expire in.
const otpExpiration = Duration(minutes: 10);

/// A handler for sending an OTP.
Handler sendOtpHandler({
  String fromEmail = 'noreply@online-service.com',
  String fromName = 'Online Service',
  String? emailSubject,
  bool debugOtps = false,
}) {
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

    final environment = context.read<Environment>();
    final testingEmail = environment['TESTING_EMAIL'];
    final testingPhoneNumber = environment['TESTING_PHONE_NUMBER'];
    final testingOtp = environment['TESTING_OTP'];

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
            subject: emailSubject ?? 'Your OTP for $fromName',
            body: 'Your OTP is $otp',
            from: fromEmail,
          );
        case OtpType.phone:
          final smsProvider = context.read<SmsProvider>();
          await smsProvider.sendSms(
            requestBody.identifier,
            'Your $fromName verification code is $otp',
          );
      }
    }

    return Response.json(
      body: SendOtpResponse(expiresAt: expiresAt, expiresIn: otpExpiration),
    );
  };
}
