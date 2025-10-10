import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:super_simple_authentication_toolkit/src/util/util.dart';

import '../main.dart';

Handler middleware(Handler handler) {
  return handler
      .use(requestLogger())
      .use(provider((_) => dataStorage))
      .use(provider((_) => logger))
      .use(provider<Environment>((_) => Platform.environment));
}
