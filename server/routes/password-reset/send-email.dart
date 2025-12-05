import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:super_simple_authentication_toolkit/super_simple_authentication_toolkit.dart';

Future<Response> onRequest(RequestContext context) async {
  final environment = context.read<Environment>();
  final resetBaseUrl = environment['PASSWORD_RESET_BASE_URL'];
  if (resetBaseUrl == null || resetBaseUrl.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'error': 'PASSWORD_RESET_BASE_URL environment variable is required',
      },
    );
  }

  final handler = sendPasswordResetEmailHandler(
    resetBaseUrl: resetBaseUrl,
    fromEmail:
        environment['PASSWORD_RESET_FROM_EMAIL'] ??
        'noreply@online-service.com',
    fromName: environment['PASSWORD_RESET_FROM_NAME'] ?? 'Online Service',
    emailSubject: environment['PASSWORD_RESET_EMAIL_SUBJECT'],
    templateId: environment['PASSWORD_RESET_TEMPLATE_ID'],
  );
  return handler(context);
}
