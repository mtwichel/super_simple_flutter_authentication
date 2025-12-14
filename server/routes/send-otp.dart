import 'package:dart_frog/dart_frog.dart';
import 'package:super_simple_authentication_toolkit/super_simple_authentication_toolkit.dart';

Future<Response> onRequest(RequestContext context) async {
  final environment = context.read<Environment>();
  final handler = sendOtpHandler(
    fromEmail: environment['EMAIL_FROM_EMAIL'] ?? 'noreply@online-service.com',
    fromName: environment['EMAIL_FROM_NAME'],
    emailSubject: environment['EMAIL_SUBJECT'],
    testingEmail: environment['TESTING_EMAIL'],
    testingPhoneNumber: environment['TESTING_PHONE_NUMBER'],
    testingOtp: environment['TESTING_OTP'],
  );
  return handler(context);
}
