import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:super_simple_authentication_toolkit/super_simple_authentication_toolkit.dart';

import '../main.dart';

Handler middleware(Handler handler) {
  return handler
      .use(requestLogger())
      .use(rateLimitMiddleware())
      .use(provider((_) => dataStorage))
      .use(provider((_) => logger))
      .use(apiKeyMiddleware(apiKey: Platform.environment['API_KEY']))
      .use(
        corsMiddleware(
          allowedOrigin: Platform.environment['ALLOWED_ORIGIN'],
          allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
          allowedHeaders: [
            'Content-Type',
            'x-api-key',
            'x-forwarded-for',
            'x-real-ip',
            'cf-connecting-ip',
            'host',
          ],
        ),
      )
      .use(provider<Environment>((_) => Platform.environment));
}
