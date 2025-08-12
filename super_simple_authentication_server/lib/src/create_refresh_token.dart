import 'dart:convert';

import 'package:super_simple_authentication_server/src/create_random_number.dart';

/// Creates a refresh token for a user.
String createRefreshToken() {
  return base64Url.encode(generateRandomNumber()).replaceAll('=', '');
}
