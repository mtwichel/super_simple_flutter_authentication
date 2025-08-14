import 'dart:convert' as convert;

import 'package:http/http.dart';
import 'package:super_simple_authentication_flutter/super_simple_authentication_flutter.dart';

/// Extension to parse HTTP responses into JSON, maps, and custom types.
extension ResponseParser on Response {
  /// Parses the response body as JSON.
  dynamic get json => convert.jsonDecode(body);

  /// Converts the JSON response to a map.
  Map<String, dynamic> get map => Map<String, dynamic>.from(json as Map);

  /// Parses the response body into a custom type.
  T parse<T>(FromJson<T> fromJson) => fromJson(map);
}
