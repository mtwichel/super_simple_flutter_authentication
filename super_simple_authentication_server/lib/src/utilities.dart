import 'package:dart_frog/dart_frog.dart';

/// The environment the server is running in.
typedef Environment = Map<String, String>;

/// The current DateTime
typedef Now = DateTime;

/// A function that parses a [Map] into a [T].
typedef FromJson<T> = T Function(Map<String, dynamic> json);

/// Extension on [Request] to get the request body as a [Map].
extension MapExtension on Request {
  /// Returns the request body as a [Map].
  Future<Map<String, dynamic>> map() async {
    final json = await this.json();
    return Map<String, dynamic>.from(json as Map);
  }

  /// Parses the request body as a [T].
  Future<T> parse<T>(FromJson<T> fromJson) async => fromJson(await map());
}
