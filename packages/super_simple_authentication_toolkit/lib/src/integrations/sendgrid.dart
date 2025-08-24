import 'dart:convert';

import 'package:http/http.dart';

/// {@template sendgrid}
/// A client for sending emails using Sendgrid.
/// {@endtemplate}
class Sendgrid {
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
}
