/// {@template email_provider}
/// An abstract interface for email providers.
/// {@endtemplate}
abstract class EmailProvider {
  /// Sends an email to the given recipient with the given subject and body.
  Future<void> sendEmail({
    required String to,
    required String subject,
    required String body,
    required String from,
    String? fromName,
  });

  /// Sends an email using a Sendgrid dynamic template.
  Future<void> sendEmailWithTemplate({
    required String to,
    required String templateId,
    required Map<String, dynamic> dynamicTemplateData,
    required String from,
    required String subject,
    String? fromName,
  });
}
