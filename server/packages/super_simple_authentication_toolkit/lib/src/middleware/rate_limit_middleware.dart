import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

/// {@template rate_limit_config}
/// Configuration for rate limiting
/// {@endtemplate}
class RateLimitConfig {
  /// {@macro rate_limit_config}
  RateLimitConfig({
    this.maxRequests = 100,
    this.window = const Duration(minutes: 1),
  });

  /// The maximum number of requests allowed within the time window.
  final int maxRequests;

  /// The time window for rate limiting.
  final Duration window;

  /// The request history for each IP.
  final Map<String, List<DateTime>> _requestHistory = {};

  /// Check if an IP is rate limited
  bool isRateLimited(String ip) {
    final now = DateTime.now();
    final requests = _requestHistory[ip] ?? [];

    // Remove expired requests
    final validRequests = requests
        .where((timestamp) => now.difference(timestamp) < window)
        .toList();

    // Update the request history
    _requestHistory[ip] = validRequests;

    // Check if limit exceeded
    if (validRequests.length >= maxRequests) {
      return true;
    }

    // Add current request
    validRequests.add(now);
    _requestHistory[ip] = validRequests;

    return false;
  }

  /// Get remaining requests for an IP
  int getRemainingRequests(String ip) {
    final now = DateTime.now();
    final requests = _requestHistory[ip] ?? [];

    // Remove expired requests
    final validRequests = requests
        .where((timestamp) => now.difference(timestamp) < window)
        .toList();

    return maxRequests - validRequests.length;
  }

  /// Get reset time for an IP
  DateTime? getResetTime(String ip) {
    final requests = _requestHistory[ip] ?? [];
    if (requests.isEmpty) return null;

    final oldestRequest = requests.reduce((a, b) => a.isBefore(b) ? a : b);
    return oldestRequest.add(window);
  }

  /// Clear rate limit data for an IP
  void clearRateLimit(String ip) {
    _requestHistory.remove(ip);
  }

  /// Clear all rate limit data
  void clearAllRateLimits() {
    _requestHistory.clear();
  }
}

/// Global rate limit configuration
final _rateLimitConfig = RateLimitConfig();

/// Rate limit middleware factory
Middleware rateLimitMiddleware({
  RateLimitConfig? config,
}) {
  return (handler) {
    final rateConfig = config ?? _rateLimitConfig;

    return (context) async {
      final request = context.request;

      // Extract IP address from headers
      var ip = request.headers['x-forwarded-for'];
      if (ip != null && ip.contains(',')) {
        // Handle multiple IPs in x-forwarded-for header
        ip = ip.split(',').first.trim();
      }

      // Fallback to other headers if x-forwarded-for is not available
      ip ??= request.headers['x-real-ip'];
      ip ??= request.headers['cf-connecting-ip']; // Cloudflare
      ip ??= request.headers['host']?.split(':').first; // Fallback to host

      // If still no IP, use a default
      ip ??= 'unknown';

      // Check if rate limited
      if (rateConfig.isRateLimited(ip)) {
        final resetTime = rateConfig.getResetTime(ip);
        final retryAfter = resetTime != null
            ? resetTime.difference(DateTime.now()).inSeconds.toString()
            : '60';

        return Response.json(
          body: {
            'error': 'Rate limit exceeded',
            'message': 'Too many requests. Please try again later.',
            'retry_after': retryAfter,
          },
          statusCode: HttpStatus.tooManyRequests,
          headers: {
            'Retry-After': retryAfter,
          },
        );
      }

      // Add rate limit headers to response
      final response = await handler(context);

      final remainingRequests = rateConfig.getRemainingRequests(ip);
      final resetTime = rateConfig.getResetTime(ip);

      return response.copyWith(
        headers: {
          ...response.headers,
          'X-RateLimit-Limit': rateConfig.maxRequests.toString(),
          'X-RateLimit-Remaining': remainingRequests.toString(),
          'X-RateLimit-Reset':
              resetTime?.millisecondsSinceEpoch.toString() ?? '',
        },
      );
    };
  };
}
