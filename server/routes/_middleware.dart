import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:super_simple_authentication_toolkit/super_simple_authentication_toolkit.dart';

import '../main.dart';

Handler middleware(Handler handler) {
  return handler
      .use(requestLogger())
      .use(rateLimitMiddleware())
      .use(provider<Now>((_) => DateTime.now()))
      .use(provider((_) => dataStorage))
      .use(provider((_) => logger))
      .use(apiKeyMiddleware(apiKey: Platform.environment['API_KEY']))
      .use(
        provider((_) {
          return switch (Platform.environment['EMAIL_PROVIDER']) {
            'fake' => FakeEmailService(stdout: stdout),
            'sendgrid' => Sendgrid(
              apiKey: Platform.environment['SENDGRID_API_KEY']!,
              baseUrl:
                  Platform.environment['SENDGRID_BASE_URL'] ??
                  'https://api.sendgrid.com',
            ),
            'smtp' => SmtpEmailProvider(
              host: Platform.environment['SMTP_HOST']!,
              port: int.parse(Platform.environment['SMTP_PORT']!),
              username: Platform.environment['SMTP_USERNAME']!,
              password: Platform.environment['SMTP_PASSWORD']!,
              useSsl: Platform.environment['SMTP_USE_SSL'] != 'false',
              allowInsecure:
                  Platform.environment['SMTP_ALLOW_INSECURE'] == 'true',
              name: Platform.environment['SMTP_NAME'],
            ),
            _ =>
              throw Exception(
                '''Invalid email provider: ${Platform.environment['EMAIL_PROVIDER']}''',
              ),
          };
        }),
      )
      .use(
        provider((_) {
          return switch (Platform.environment['SMS_PROVIDER']) {
            'fake' => FakeSms(stdout: stdout),
            'twilio' => Twilio(
              accountSid: Platform.environment['TWILIO_ACCOUNT_SID']!,
              authenticationToken: Platform.environment['TWILIO_AUTH_TOKEN']!,
              messagingServiceSid:
                  Platform.environment['TWILIO_MESSAGING_SERVICE_SID']!,
            ),
            'textbelt' => Textbelt(
              apiKey: Platform.environment['TEXTBELT_API_KEY']!,
            ),
            _ =>
              throw Exception(
                '''Invalid SMS provider: ${Platform.environment['SMS_PROVIDER']}''',
              ),
          };
        }),
      )
      .use(
        corsMiddleware(
          allowedOrigin: Platform.environment['ALLOWED_ORIGIN'],
          allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
          allowedHeaders: [
            'Content-Type',
            'x-api-key',
            'x-forwarded-for',
            'x-real-ip',
            'cf-connecting-ip',
            'host',
          ],
        ),
      )
      .use(provider<Environment>((_) => Platform.environment));
}
