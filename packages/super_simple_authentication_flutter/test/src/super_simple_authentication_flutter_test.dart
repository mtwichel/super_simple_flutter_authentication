// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:super_simple_authentication_flutter/super_simple_authentication_flutter.dart';

class _MockClient extends Mock implements http.Client {}

void main() {
  group('SuperSimpleAuthentication', () {
    late _MockClient client;

    setUp(() {
      client = _MockClient();
    });

    test('can be instantiated', () {
      expect(
        SuperSimpleAuthentication(client: client, host: 'localhost'),
        isNotNull,
      );
    });
  });
}
