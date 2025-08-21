import 'dart:convert' as convert;

import 'package:http/http.dart';
import 'package:super_simple_authentication_flutter/super_simple_authentication_flutter.dart';

/// A helper extension on the [Response] class to make it easier to parse JSON
extension ResponseParser on Response {
  /// Parses the body as JSON
  dynamic get json => convert.jsonDecode(body);

  /// Parses the body as a Map
  Map<String, dynamic> get map => Map<String, dynamic>.from(json as Map);

  /// Parses the body as a [T]
  ///
  /// This is a generic method that will parse the body as a [T]
  /// using the provided [fromJson] function.
  ///
  /// Example:
  /// ```dart
  /// final response = await http.get(url);
  /// final user = response.parse(User.fromJson);
  /// ```
  T parse<T>(FromJson<T> fromJson) => fromJson(map);
}
