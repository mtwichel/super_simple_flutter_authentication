/// {@template sms_provider}
/// An abstract interface for SMS providers.
/// {@endtemplate}
// ignore: one_member_abstracts
abstract class SmsProvider {
  /// Sends an SMS message to the given phone number with the given body.
  Future<void> sendSms(String to, String body);
}
