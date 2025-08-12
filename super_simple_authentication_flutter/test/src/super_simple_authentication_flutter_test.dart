// ignore_for_file: prefer_const_constructors

import 'package:api_client/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:super_simple_authentication_flutter/super_simple_authentication_flutter.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  group('SuperSimpleAuthentication', () {
    late _MockApiClient client;

    setUp(() {
      client = _MockApiClient();
    });

    test('can be instantiated', () {
      expect(
        SuperSimpleAuthentication(client: client),
        isNotNull,
      );
    });
  });
}
