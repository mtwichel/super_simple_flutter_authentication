import 'package:super_simple_authentication_toolkit/src/middleware/rate_limit_middleware.dart';
import 'package:test/test.dart';

void main() {
  group('RateLimitConfig', () {
    test('should allow requests within limit', () {
      final config = RateLimitConfig(maxRequests: 5);
      const ip = '192.168.1.1';

      // Make 5 requests
      for (var i = 0; i < 5; i++) {
        expect(config.isRateLimited(ip), false);
      }

      // 6th request should be rate limited
      expect(config.isRateLimited(ip), true);
    });

    test('should reset after window expires', () async {
      final config = RateLimitConfig(
        maxRequests: 1,
        window: const Duration(milliseconds: 100),
      );
      const ip = '192.168.1.1';

      // First request should be allowed
      expect(config.isRateLimited(ip), false);

      // Second request should be rate limited
      expect(config.isRateLimited(ip), true);

      // Wait for window to expire
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Request should be allowed again
      expect(config.isRateLimited(ip), false);
    });

    test('should track different IPs separately', () {
      final config = RateLimitConfig(maxRequests: 1);

      // First IP
      expect(config.isRateLimited('192.168.1.1'), false);
      expect(config.isRateLimited('192.168.1.1'), true);

      // Second IP should be allowed
      expect(config.isRateLimited('192.168.1.2'), false);
    });

    test('should return correct remaining requests', () {
      final config = RateLimitConfig(maxRequests: 5);
      const ip = '192.168.1.1';

      expect(config.getRemainingRequests(ip), 5);

      config.isRateLimited(ip); // Make one request
      expect(config.getRemainingRequests(ip), 4);

      config.isRateLimited(ip); // Make another request
      expect(config.getRemainingRequests(ip), 3);
    });

    test('should clear rate limit data', () {
      final config = RateLimitConfig(maxRequests: 1);
      const ip = '192.168.1.1';

      config.isRateLimited(ip);
      expect(config.isRateLimited(ip), true);

      config.clearRateLimit(ip);
      expect(config.isRateLimited(ip), false);
    });

    test('should clear all rate limit data', () {
      final config = RateLimitConfig(maxRequests: 1)
        ..isRateLimited('192.168.1.1')
        ..isRateLimited('192.168.1.2');

      expect(config.isRateLimited('192.168.1.1'), true);
      expect(config.isRateLimited('192.168.1.2'), true);

      config.clearAllRateLimits();

      expect(config.isRateLimited('192.168.1.1'), false);
      expect(config.isRateLimited('192.168.1.2'), false);
    });

    test('should return correct reset time', () {
      final config = RateLimitConfig(maxRequests: 1);
      const ip = '192.168.1.1';

      // No requests yet
      expect(config.getResetTime(ip), null);

      // Make a request
      config.isRateLimited(ip);

      final resetTime = config.getResetTime(ip);
      expect(resetTime, isNotNull);
      expect(resetTime!.isAfter(DateTime.now()), true);
    });

    test('should handle edge case with zero max requests', () {
      final config = RateLimitConfig(maxRequests: 0);
      const ip = '192.168.1.1';

      // Should be rate limited immediately
      expect(config.isRateLimited(ip), true);
      expect(config.getRemainingRequests(ip), 0);
    });

    test('should handle very short windows', () async {
      final config = RateLimitConfig(
        maxRequests: 2,
        window: const Duration(milliseconds: 50),
      );
      const ip = '192.168.1.1';

      // Make two requests quickly
      expect(config.isRateLimited(ip), false);
      expect(config.isRateLimited(ip), false);

      // Third should be rate limited
      expect(config.isRateLimited(ip), true);

      // Wait for window to expire
      await Future<void>.delayed(const Duration(milliseconds: 60));

      // Should be allowed again
      expect(config.isRateLimited(ip), false);
    });
  });
}
