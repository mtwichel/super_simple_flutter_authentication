import 'dart:io';

import 'package:super_simple_authentication_toolkit/super_simple_authentication_toolkit.dart';

/// {@template fake_sms}
/// A fake SMS service for testing.
/// {@endtemplate}
class FakeSms implements SmsProvider {
  /// {@macro fake_sms}
  const FakeSms({required Stdout stdout}) : _stdout = stdout;

  final Stdout _stdout;

  @override
  Future<void> sendSms(String to, String body) async {
    _stdout.writeln(
      '''
Sending SMS
[TO] $to
$body''',
    );
  }
}
