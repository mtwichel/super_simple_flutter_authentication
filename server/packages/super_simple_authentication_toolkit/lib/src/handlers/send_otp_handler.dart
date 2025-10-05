import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:super_simple_authentication_toolkit/super_simple_authentication_toolkit.dart';

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
    final {'identifier': String identifier, 'type': String type} = await context
        .request
        .map();

    final dataStorage = context.read<DataStorage>();

    await dataStorage.revokeOtpsFor(identifier: identifier, channel: type);

    final environment = context.read<Environment>();
    final testingEmail = environment['TESTING_EMAIL'];
    final testingPhoneNumber = environment['TESTING_PHONE_NUMBER'];
    final testingOtp = environment['TESTING_OTP'];

    final usingTestOtp =
        (identifier == testingEmail || identifier == testingPhoneNumber) &&
        testingOtp != null;

    final otp = usingTestOtp ? testingOtp : createOtp();

    final hashedOtp = await hashOtp(otp);
    final now = context.read<Now>();
    final expiresAt = now.add(otpExpiration);

    await dataStorage.createOtp(
      identifier: identifier,
      channel: type,
      hashedOtp: hashedOtp,
      expiresAt: expiresAt.toIso8601String(),
    );

    if (debugOtps) {
      // If debugging, print the OTP to the console
      // ignore: avoid_print
      print('OTP: $otp');
    } else if (!usingTestOtp) {
      switch (type) {
        case 'email':
          final sendgrid = context.read<Sendgrid>();
          await sendgrid.sendEmail(
            to: identifier,
            subject: emailSubject ?? 'Your OTP for $fromName',
            body: 'Your OTP is $otp',
            from: fromEmail,
          );
        case 'phone':
          final smsProvider = context.read<SmsProvider>();
          await smsProvider.sendSms(
            identifier,
            'Your $fromName verification code is $otp',
          );
      }
    }

    return Response.json(
      body: {'expiresAt': expiresAt, 'expiresIn': otpExpiration, 'error': null},
    );
  };
}
