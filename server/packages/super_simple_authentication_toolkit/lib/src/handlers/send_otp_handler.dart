import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:super_simple_authentication_toolkit/super_simple_authentication_toolkit.dart';

/// The duration the OTP will expire in.
const otpExpiration = Duration(minutes: 10);

/// A handler for sending an OTP.
Handler sendOtpHandler({
  required String fromEmail,
  String? fromName,
  String? emailSubject,
  String? testingEmail,
  String? testingPhoneNumber,
  String? testingOtp,
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

    if (!usingTestOtp) {
      switch (type) {
        case 'email':
          final emailProvider = context.read<EmailProvider>();
          await emailProvider.sendEmail(
            to: identifier,
            subject: emailSubject ?? 'Your One-Time passcode for $fromName',
            body: 'Your OTP is $otp',
            from: fromEmail,
            fromName: fromName,
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
      body: {
        'expiresAt': expiresAt.toIso8601String(),
        'expiresInSeconds': otpExpiration.inSeconds,
        'error': null,
      },
    );
  };
}
