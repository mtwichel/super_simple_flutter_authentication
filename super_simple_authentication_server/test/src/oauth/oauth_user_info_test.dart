import 'package:super_simple_authentication_server/src/oauth/oauth.dart';
import 'package:test/test.dart';

void main() {
  group('OAuthUserInfo', () {
    test('creates instance with required sub field', () {
      const userInfo = OAuthUserInfo(sub: 'user123');

      expect(userInfo.sub, equals('user123'));
      expect(userInfo.email, isNull);
      expect(userInfo.emailVerified, isNull);
      expect(userInfo.name, isNull);
      expect(userInfo.picture, isNull);
      expect(userInfo.additionalClaims, isEmpty);
    });

    test('creates instance with all fields populated', () {
      const userInfo = OAuthUserInfo(
        sub: 'user123',
        email: 'user@example.com',
        emailVerified: true,
        name: 'John Doe',
        picture: 'https://example.com/avatar.jpg',
        additionalClaims: {'custom_claim': 'custom_value'},
      );

      expect(userInfo.sub, equals('user123'));
      expect(userInfo.email, equals('user@example.com'));
      expect(userInfo.emailVerified, isTrue);
      expect(userInfo.name, equals('John Doe'));
      expect(userInfo.picture, equals('https://example.com/avatar.jpg'));
      expect(
        userInfo.additionalClaims,
        equals({'custom_claim': 'custom_value'}),
      );
    });

    test('copyWith creates new instance with updated fields', () {
      const original = OAuthUserInfo(
        sub: 'user123',
        email: 'user@example.com',
        emailVerified: false,
      );

      final updated = original.copyWith(
        email: 'newemail@example.com',
        emailVerified: true,
        name: 'John Doe',
      );

      expect(updated.sub, equals('user123')); // unchanged
      expect(updated.email, equals('newemail@example.com')); // changed
      expect(updated.emailVerified, isTrue); // changed
      expect(updated.name, equals('John Doe')); // added
      expect(updated.picture, isNull); // unchanged
    });

    test('copyWith with null values keeps original values', () {
      const original = OAuthUserInfo(
        sub: 'user123',
        email: 'user@example.com',
        emailVerified: true,
        name: 'John Doe',
      );

      final updated = original.copyWith();

      expect(updated.sub, equals(original.sub));
      expect(updated.email, equals(original.email));
      expect(updated.emailVerified, equals(original.emailVerified));
      expect(updated.name, equals(original.name));
      expect(updated.picture, equals(original.picture));
      expect(updated.additionalClaims, equals(original.additionalClaims));
    });

    test('equality works correctly', () {
      const userInfo1 = OAuthUserInfo(
        sub: 'user123',
        email: 'user@example.com',
        emailVerified: true,
        name: 'John Doe',
        additionalClaims: {'custom': 'value'},
      );

      const userInfo2 = OAuthUserInfo(
        sub: 'user123',
        email: 'user@example.com',
        emailVerified: true,
        name: 'John Doe',
        additionalClaims: {'custom': 'value'},
      );

      const userInfo3 = OAuthUserInfo(
        sub: 'user456',
        email: 'user@example.com',
        emailVerified: true,
        name: 'John Doe',
        additionalClaims: {'custom': 'value'},
      );

      expect(userInfo1, equals(userInfo2));
      expect(userInfo1, isNot(equals(userInfo3)));
      expect(userInfo1.hashCode, equals(userInfo2.hashCode));
    });

    test('equality handles null values correctly', () {
      const userInfo1 = OAuthUserInfo(sub: 'user123');
      const userInfo2 = OAuthUserInfo(sub: 'user123');
      const userInfo3 = OAuthUserInfo(
        sub: 'user123',
        email: 'user@example.com',
      );

      expect(userInfo1, equals(userInfo2));
      expect(userInfo1, isNot(equals(userInfo3)));
    });

    test('equality handles different additional claims', () {
      const userInfo1 = OAuthUserInfo(
        sub: 'user123',
        additionalClaims: {'claim1': 'value1', 'claim2': 'value2'},
      );

      const userInfo2 = OAuthUserInfo(
        sub: 'user123',
        additionalClaims: {'claim1': 'value1', 'claim2': 'value2'},
      );

      const userInfo3 = OAuthUserInfo(
        sub: 'user123',
        additionalClaims: {'claim1': 'value1', 'claim2': 'different'},
      );

      const userInfo4 = OAuthUserInfo(
        sub: 'user123',
        additionalClaims: {'claim1': 'value1'},
      );

      expect(userInfo1, equals(userInfo2));
      expect(userInfo1, isNot(equals(userInfo3)));
      expect(userInfo1, isNot(equals(userInfo4)));
    });

    test('toString provides readable representation', () {
      const userInfo = OAuthUserInfo(
        sub: 'user123',
        email: 'user@example.com',
        emailVerified: true,
        name: 'John Doe',
        picture: 'https://example.com/avatar.jpg',
        additionalClaims: {'custom': 'value'},
      );

      final string = userInfo.toString();

      expect(string, contains('OAuthUserInfo('));
      expect(string, contains('sub: user123'));
      expect(string, contains('email: user@example.com'));
      expect(string, contains('emailVerified: true'));
      expect(string, contains('name: John Doe'));
      expect(string, contains('picture: https://example.com/avatar.jpg'));
      expect(string, contains('additionalClaims: {custom: value}'));
    });

    test('toString handles null values', () {
      const userInfo = OAuthUserInfo(sub: 'user123');

      final string = userInfo.toString();

      expect(string, contains('sub: user123'));
      expect(string, contains('email: null'));
      expect(string, contains('emailVerified: null'));
      expect(string, contains('name: null'));
      expect(string, contains('picture: null'));
      expect(string, contains('additionalClaims: {}'));
    });
  });
}
