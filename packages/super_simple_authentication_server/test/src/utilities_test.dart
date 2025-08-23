// ignore_for_file: avoid_dynamic_calls

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:super_simple_authentication_server/src/util/extensions.dart';
import 'package:test/test.dart';

class MockRequest extends Mock implements Request {}

// Test classes for parsing tests
class TestUser {
  TestUser({required this.name, required this.age});

  factory TestUser.fromJson(Map<String, dynamic> json) {
    return TestUser(name: json['name'] as String, age: json['age'] as int);
  }
  final String name;
  final int age;
}

class UserPreferences {
  UserPreferences({required this.theme, required this.notifications});

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      theme: json['theme'] as String,
      notifications: json['notifications'] as bool,
    );
  }
  final String theme;
  final bool notifications;
}

class User {
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.preferences,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      preferences: UserPreferences.fromJson(
        json['preferences'] as Map<String, dynamic>,
      ),
    );
  }
  final int id;
  final String name;
  final String email;
  final UserPreferences preferences;
}

class RequestData {
  RequestData({required this.user, required this.timestamp});

  factory RequestData.fromJson(Map<String, dynamic> json) {
    return RequestData(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      timestamp: json['timestamp'] as String,
    );
  }
  final User user;
  final String timestamp;
}

void main() {
  group('MapExtension', () {
    late MockRequest mockRequest;

    setUp(() {
      mockRequest = MockRequest();
    });

    group('map()', () {
      test('returns Map<String, dynamic> from valid JSON', () async {
        // Arrange
        final expectedJson = {'key': 'value', 'number': 42, 'boolean': true};
        when(() => mockRequest.json()).thenAnswer((_) async => expectedJson);

        // Act
        final result = await mockRequest.map();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result, equals(expectedJson));
        verify(() => mockRequest.json()).called(1);
      });

      test('returns empty map from empty JSON object', () async {
        // Arrange
        final expectedJson = <String, dynamic>{};
        when(() => mockRequest.json()).thenAnswer((_) async => expectedJson);

        // Act
        final result = await mockRequest.map();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result, isEmpty);
        verify(() => mockRequest.json()).called(1);
      });

      test('handles nested JSON objects', () async {
        // Arrange
        final expectedJson = {
          'user': {
            'name': 'John Doe',
            'age': 30,
            'address': {'street': '123 Main St', 'city': 'Test City'},
          },
          'active': true,
        };
        when(() => mockRequest.json()).thenAnswer((_) async => expectedJson);

        // Act
        final result = await mockRequest.map();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['user'], isA<Map<String, dynamic>>());
        expect(result['user']['name'], equals('John Doe'));
        expect(result['user']['address']['city'], equals('Test City'));
        verify(() => mockRequest.json()).called(1);
      });

      test('handles arrays in JSON', () async {
        // Arrange
        final expectedJson = {
          'items': ['item1', 'item2', 'item3'],
          'numbers': [1, 2, 3, 4, 5],
          'mixed': [1, 'string', true, null],
        };
        when(() => mockRequest.json()).thenAnswer((_) async => expectedJson);

        // Act
        final result = await mockRequest.map();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['items'], isA<List<dynamic>>());
        expect(result['items'], equals(['item1', 'item2', 'item3']));
        expect(result['numbers'], equals([1, 2, 3, 4, 5]));
        verify(() => mockRequest.json()).called(1);
      });

      test('throws when json() throws an exception', () async {
        // Arrange
        when(
          () => mockRequest.json(),
        ).thenThrow(Exception('JSON parsing failed'));

        // Act & Assert
        expect(() => mockRequest.map(), throwsA(isA<Exception>()));
        verify(() => mockRequest.json()).called(1);
      });
    });

    group('parse<T>()', () {
      test('parses JSON to custom type using FromJson function', () async {
        // Arrange
        final jsonData = {'name': 'John Doe', 'age': 30};
        when(() => mockRequest.json()).thenAnswer((_) async => jsonData);

        // Act
        final result = await mockRequest.parse<TestUser>(TestUser.fromJson);

        // Assert
        expect(result, isA<TestUser>());
        expect(result.name, equals('John Doe'));
        expect(result.age, equals(30));
        verify(() => mockRequest.json()).called(1);
      });

      test('parses JSON to primitive types', () async {
        // Arrange
        final jsonData = {'value': 'test string'};
        when(() => mockRequest.json()).thenAnswer((_) async => jsonData);

        // Act
        final result = await mockRequest.parse<String>(
          (json) => json['value'] as String,
        );

        // Assert
        expect(result, isA<String>());
        expect(result, equals('test string'));
        verify(() => mockRequest.json()).called(1);
      });

      test('parses JSON to int', () async {
        // Arrange
        final jsonData = {'count': 42};
        when(() => mockRequest.json()).thenAnswer((_) async => jsonData);

        // Act
        final result = await mockRequest.parse<int>(
          (json) => json['count'] as int,
        );

        // Assert
        expect(result, isA<int>());
        expect(result, equals(42));
        verify(() => mockRequest.json()).called(1);
      });

      test('parses JSON to bool', () async {
        // Arrange
        final jsonData = {'active': true};
        when(() => mockRequest.json()).thenAnswer((_) async => jsonData);

        // Act
        final result = await mockRequest.parse<bool>(
          (json) => json['active'] as bool,
        );

        // Assert
        expect(result, isA<bool>());
        expect(result, isTrue);
        verify(() => mockRequest.json()).called(1);
      });

      test('parses JSON to List', () async {
        // Arrange
        final jsonData = {
          'items': ['a', 'b', 'c'],
        };
        when(() => mockRequest.json()).thenAnswer((_) async => jsonData);

        // Act
        final result = await mockRequest.parse<List<String>>(
          (json) => (json['items'] as List).cast<String>(),
        );

        // Assert
        expect(result, isA<List<String>>());
        expect(result, equals(['a', 'b', 'c']));
        verify(() => mockRequest.json()).called(1);
      });

      test('throws when FromJson function throws an exception', () async {
        // Arrange
        final jsonData = {'invalid': 'data'};
        when(() => mockRequest.json()).thenAnswer((_) async => jsonData);

        // Act & Assert
        expect(
          () => mockRequest.parse<String>(
            (json) => throw Exception('Parsing failed'),
          ),
          throwsA(isA<Exception>()),
        );
        verify(() => mockRequest.json()).called(1);
      });

      test(
        'throws when FromJson function returns null for non-nullable type',
        () async {
          // Arrange
          final jsonData = {'missing': 'data'};
          when(() => mockRequest.json()).thenAnswer((_) async => jsonData);

          // Act & Assert
          expect(
            () => mockRequest.parse<String>(
              (json) => json['nonexistent'] as String,
            ),
            throwsA(isA<TypeError>()),
          );
          verify(() => mockRequest.json()).called(1);
        },
      );
    });

    group('integration tests', () {
      test('map() and parse() work together correctly', () async {
        // Arrange
        final jsonData = {
          'user': {
            'id': 1,
            'name': 'Jane Smith',
            'email': 'jane@example.com',
            'preferences': {'theme': 'dark', 'notifications': true},
          },
          'timestamp': '2024-01-01T00:00:00Z',
        };
        when(() => mockRequest.json()).thenAnswer((_) async => jsonData);

        // Act
        final result = await mockRequest.parse<RequestData>(
          RequestData.fromJson,
        );

        // Assert
        expect(result, isA<RequestData>());
        expect(result.user.id, equals(1));
        expect(result.user.name, equals('Jane Smith'));
        expect(result.user.email, equals('jane@example.com'));
        expect(result.user.preferences.theme, equals('dark'));
        expect(result.user.preferences.notifications, isTrue);
        expect(result.timestamp, equals('2024-01-01T00:00:00Z'));
        verify(() => mockRequest.json()).called(1);
      });
    });
  });
}
