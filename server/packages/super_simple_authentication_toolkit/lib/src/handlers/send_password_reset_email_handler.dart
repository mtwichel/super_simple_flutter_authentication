import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:super_simple_authentication_toolkit/super_simple_authentication_toolkit.dart';

/// The duration the password reset token will expire in.
const passwordResetTokenExpiration = Duration(hours: 1);

/// A handler for sending a password reset email.
Handler sendPasswordResetEmailHandler({
  required String resetBaseUrl,
  String fromEmail = 'noreply@online-service.com',
  String fromName = 'Online Service',
  String? emailSubject,
  String? templateId,
  Map<String, dynamic> Function({
    required String resetLink,
    required String fromName,
    required int expiresInHours,
  })?
  buildTemplateData,
}) {
  return (context) async {
    if (context.request.method != HttpMethod.post) {
      return Response(statusCode: HttpStatus.methodNotAllowed);
    }
    final {'email': String email} = await context.request.map();

    final dataStorage = context.read<DataStorage>();
    final users = await dataStorage.getUsersByEmail(email);

    // Security best practice: Don't reveal if email exists
    // Always return the same response regardless of whether user exists
    final now = context.read<Now>();
    final expiresAt = now.add(passwordResetTokenExpiration);

    // Only process if user exists
    if (users.isNotEmpty && users.first.email != null) {
      final userId = users.first.id;

      // Revoke existing password reset tokens for this user
      await dataStorage.revokePasswordResetTokens(userId: userId);

      // Generate secure random token
      final token = createPasswordResetToken();

      // Hash token before storing
      final hashedToken = await hashPasswordResetToken(token);

      // Store hashed token with expiration
      await dataStorage.createPasswordResetToken(
        userId: userId,
        hashedToken: hashedToken,
        expiresAt: expiresAt.toIso8601String(),
      );

      // Send email with reset link
      final emailProvider = context.read<EmailProvider>();
      final resetLink = '$resetBaseUrl/reset-password?token=$token';

      if (templateId != null) {
        // Use Sendgrid template
        final templateData =
            buildTemplateData?.call(
              resetLink: resetLink,
              fromName: fromName,
              expiresInHours: 1,
            ) ??
            {
              'resetLink': resetLink,
              'fromName': fromName,
              'expiresInHours': 1,
            };

        await emailProvider.sendEmailWithTemplate(
          to: email,
          templateId: templateId,
          dynamicTemplateData: templateData,
          from: fromEmail,
          subject: emailSubject ?? 'Reset your password for $fromName',
        );
      } else {
        // Use plain text email
        await emailProvider.sendEmail(
          to: email,
          subject: emailSubject ?? 'Reset your password for $fromName',
          body:
              '''Click the following link to reset your password:\n\n$resetLink\n\nThis link will expire in 1 hour.''',
          from: fromEmail,
        );
      }
    }

    // Return success response (even if email doesn't exist)
    return Response.json(
      body: {
        'expiresAt': expiresAt.toIso8601String(),
        'expiresIn': passwordResetTokenExpiration.inSeconds,
        'error': null,
      },
    );
  };
}
