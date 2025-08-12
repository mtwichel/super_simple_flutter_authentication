import 'dart:convert' as convert;

import 'package:http/http.dart';
import 'package:super_simple_authentication_flutter/super_simple_authentication_flutter.dart';

extension ResponseParser on Response {
  dynamic get json => convert.jsonDecode(body);
  Map<String, dynamic> get map => Map<String, dynamic>.from(json as Map);
  T parse<T>(FromJson<T> fromJson) => fromJson(map);
}
