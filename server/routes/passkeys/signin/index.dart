import 'package:dart_frog/dart_frog.dart';
import 'package:super_simple_authentication_toolkit/super_simple_authentication_toolkit.dart';

Future<Response> onRequest(RequestContext context) async {
  final handler = passkeySignInHandler();
  return handler(context);
}

