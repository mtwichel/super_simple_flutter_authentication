import 'dart:convert';

import 'package:http/http.dart';
import 'package:super_simple_authentication_server/src/integrations/sms_provider.dart';

/// {@template twilio}
/// A client for sending SMS messages using Twilio.
/// {@endtemplate}
class Twilio extends SmsProvider {
  /// {@macro twilio}
  Twilio({
    required String accountSid,
    required String authenticationToken,
    required String messagingServiceSid,
    Client? client,
  }) : _accountSid = accountSid,
       _authenticationToken = authenticationToken,
       _messagingServiceSid = messagingServiceSid,
       _client = client ?? Client();

  final String _accountSid;
  final String _authenticationToken;
  final String _messagingServiceSid;
  final Client _client;

  /// Sends an SMS message to the given phone number with the given body.
  @override
  Future<void> sendSms(String to, String body) async {
    final authenticationHeader = base64Encode(
      utf8.encode('$_accountSid:$_authenticationToken'),
    );
    final response = await _client.post(
      Uri.parse(
        'https://api.twilio.com/2010-04-01/Accounts/$_accountSid/Messages.json',
      ),
      body: {'To': to, 'From': _messagingServiceSid, 'Body': body},
      headers: {
        'Authorization': 'Basic $authenticationHeader',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );

    if (response.statusCode != 200) {
      // ignore: avoid_print
      print(response.statusCode);
      // ignore: avoid_print
      print(response.body);
      throw Exception('Failed to send SMS to $to');
    }
  }
}
