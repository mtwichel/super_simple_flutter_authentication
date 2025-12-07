import 'dart:convert';

import 'package:http/http.dart';
import 'package:super_simple_authentication_toolkit/super_simple_authentication_toolkit.dart';

/// {@template sendgrid}
/// A client for sending emails using Sendgrid.
/// {@endtemplate}
class Sendgrid implements EmailProvider {
  /// {@macro sendgrid}
  Sendgrid({required String apiKey, required String baseUrl})
    : _apiKey = apiKey,
      _baseUrl = baseUrl,
      _client = Client();

  final String _apiKey;
  final String _baseUrl;
  final Client _client;

  /// Sends an email using Sendgrid.
  ///
  /// [to] is the email address of the recipient.
  /// [subject] is the subject of the email.
  /// [body] is the body of the email.
  /// [from] is the email address of the sender.
  @override
  Future<void> sendEmail({
    required String to,
    required String subject,
    required String body,
    required String from,
  }) async {
    await _client.post(
      Uri.parse('$_baseUrl/v3/mail/send'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'personalizations': [
          {
            'to': [
              {'email': to},
            ],
            'subject': subject,
          },
        ],
        'from': {'email': from},
        'content': [
          {'type': 'text/plain', 'value': body},
        ],
      }),
    );
  }

  /// Sends an email using a Sendgrid dynamic template.
  ///
  /// [to] is the email address of the recipient.
  /// [templateId] is the Sendgrid dynamic template ID.
  /// [dynamicTemplateData] is a map of key-value pairs to substitute in the
  /// template.
  /// [from] is the email address of the sender.
  /// [subject] is optional and can be overridden if the template has a subject.
  ///
  /// See https://www.twilio.com/docs/sendgrid/api-reference/mail-send/mail-send
  /// for more information about Sendgrid templates.
  @override
  Future<void> sendEmailWithTemplate({
    required String to,
    required String templateId,
    required Map<String, dynamic> dynamicTemplateData,
    required String from,
    String? subject,
  }) async {
    final personalization = {
      'to': [
        {'email': to},
      ],
      'dynamic_template_data': dynamicTemplateData,
    };

    if (subject != null) {
      personalization['subject'] = subject;
    }

    await _client.post(
      Uri.parse('$_baseUrl/v3/mail/send'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'personalizations': [personalization],
        'from': {'email': from},
        'template_id': templateId,
      }),
    );
  }
}
