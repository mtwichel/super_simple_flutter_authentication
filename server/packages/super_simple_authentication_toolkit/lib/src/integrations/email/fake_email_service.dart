import 'dart:io';

import 'package:super_simple_authentication_toolkit/super_simple_authentication_toolkit.dart';

/// {@template fake_email_service}
/// A fake email service for testing.
/// {@endtemplate}
class FakeEmailService implements EmailProvider {
  /// {@macro fake_email_service}
  const FakeEmailService({
    required Stdout stdout,
  }) : _stdout = stdout;

  final Stdout _stdout;

  @override
  Future<void> sendEmail({
    required String to,
    required String subject,
    required String body,
    required String from,
    String? fromName,
  }) async {
    _stdout.writeln(
      '''
Sending email
[TO] $to
[FROM] $from
[FROM NAME] $fromName
[SUBJECT] $subject
$body''',
    );
  }

  @override
  Future<void> sendEmailWithTemplate({
    required String to,
    required String templateId,
    required Map<String, dynamic> dynamicTemplateData,
    required String from,
    String? subject,
    String? fromName,
  }) async {
    _stdout.writeln(
      '''
Sending email
[TO] $to
[FROM] $from
[SUBJECT] $subject
[FROM NAME] $fromName
[TEMPLATE ID] $templateId
$dynamicTemplateData''',
    );
  }
}
