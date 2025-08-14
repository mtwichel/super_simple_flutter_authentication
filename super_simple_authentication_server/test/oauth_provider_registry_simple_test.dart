import 'package:super_simple_authentication_server/src/oauth/oauth.dart';
import 'package:test/test.dart';

void main() {
  test('OAuthProviderRegistry basic functionality', () {
    final registry = OAuthProviderRegistry();

    const config = OAuthProviderConfig(
      id: 'test',
      issuer: 'https://test.com',
      clientId: 'test-client-id',
    );

    registry.registerProvider(config);

    expect(registry.getProvider('test'), equals(config));
    expect(registry.getRegisteredProviders(), contains('test'));
  });
}
