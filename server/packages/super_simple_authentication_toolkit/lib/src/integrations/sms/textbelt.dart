import 'dart:convert';

import 'package:http/http.dart';
import 'package:super_simple_authentication_toolkit/src/integrations/sms/sms_provider.dart';

/// {@template textbelt}
/// A client for sending SMS messages using Textbelt.
/// {@endtemplate}
class Textbelt extends SmsProvider {
  /// {@macro textbelt}
  Textbelt({required String apiKey, Client? client})
    : _apiKey = apiKey,
      _client = client ?? Client();

  final String _apiKey;
  final Client _client;

  /// Sends an SMS message to the given phone number with the given body.
  @override
  Future<void> sendSms(String to, String body) async {
    final strippedPhoneNumber = to.replaceAll(RegExp(r'[\s+\-()\n]'), '');
    final response = await _client.post(
      Uri.parse('https://textbelt.com/text'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': strippedPhoneNumber,
        'message': body,
        'key': _apiKey,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send SMS to $to');
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    final success = responseData['success'] as bool?;

    if (success != true) {
      final error = responseData['error'] as String? ?? 'Unknown error';
      throw Exception('Failed to send SMS to $to: $error');
    }
  }
}
