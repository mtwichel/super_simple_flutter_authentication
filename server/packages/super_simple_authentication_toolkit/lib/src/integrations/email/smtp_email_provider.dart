import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:super_simple_authentication_toolkit/super_simple_authentication_toolkit.dart';

/// {@template smtp_email_provider}
/// A client for sending emails using SMTP.
/// {@endtemplate}
class SmtpEmailProvider implements EmailProvider {
  /// {@macro smtp_email_provider}
  SmtpEmailProvider({
    required String host,
    required int port,
    required String username,
    required String password,
    bool useSsl = true,
    bool allowInsecure = false,
    String? name,
  }) : _host = host,
       _port = port,
       _username = username,
       _password = password,
       _useSsl = useSsl,
       _allowInsecure = allowInsecure,
       _name = name;

  final String _host;
  final int _port;
  final String _username;
  final String _password;
  final bool _useSsl;
  final bool _allowInsecure;
  final String? _name;

  SmtpServer get _smtpServer {
    if (_useSsl) {
      return SmtpServer(
        _host,
        port: _port,
        username: _username,
        password: _password,
        ssl: true,
        allowInsecure: _allowInsecure,
        name: _name,
      );
    } else {
      return SmtpServer(
        _host,
        port: _port,
        username: _username,
        password: _password,
        allowInsecure: _allowInsecure,
        name: _name,
      );
    }
  }

  /// Sends an email using SMTP.
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
    final message = Message()
      ..from = Address(from)
      ..recipients.add(to)
      ..subject = subject
      ..text = body;

    await send(message, _smtpServer);
  }

  /// Sends an email using a template.
  ///
  /// **Note:** SMTP does not support dynamic templates like SendGrid.
  /// This method will throw an [UnimplementedError] as template support
  /// would require a custom template engine implementation.
  ///
  /// For template-based emails, consider using SendGrid or implementing
  /// a custom template substitution before calling [sendEmail].
  @override
  Future<void> sendEmailWithTemplate({
    required String to,
    required String templateId,
    required Map<String, dynamic> dynamicTemplateData,
    required String from,
    String? subject,
  }) async {
    throw UnimplementedError(
      'SMTP does not support dynamic templates. '
      'Use sendEmail() with pre-rendered content instead, '
      'or use SendGrid for template support.',
    );
  }
}
