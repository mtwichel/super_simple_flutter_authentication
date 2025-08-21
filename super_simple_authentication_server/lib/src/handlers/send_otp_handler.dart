import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:shared_authentication_objects/shared_authentication_objects.dart';
import 'package:super_simple_authentication_server/src/data_storage/data_storage.dart';
import 'package:super_simple_authentication_server/src/util/util.dart';
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

    final dataStorage = context.read<DataStorage>();

    await dataStorage.revokeOtpsFor(
      identifier: requestBody.identifier,
      channel: requestBody.type.name,
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

    await dataStorage.createOtp(
      identifier: requestBody.identifier,
      channel: requestBody.type.name,
      hashedOtp: hashedOtp,
      expiresAt: expiresAt.toIso8601String(),
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
