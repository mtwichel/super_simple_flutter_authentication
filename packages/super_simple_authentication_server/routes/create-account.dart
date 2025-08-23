import 'package:dart_frog/dart_frog.dart';
import 'package:super_simple_authentication_server/super_simple_authentication_server.dart';

Future<Response> onRequest(RequestContext context) async {
  final handler = createAccountHandler();
  return handler(context);
}
