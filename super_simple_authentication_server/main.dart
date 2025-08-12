import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:postgres_builder/postgres_builder.dart';

late PostgresBuilder database;

Future<void> init(InternetAddress ip, int port) async {
  final temp = DirectPostgresBuilder(
    debug: true,
    logger: (sql) {
      // ignore: avoid_print
      print(sql);
    },
    customTypeConverter: (input) {
      if (input is DateTime) {
        return input.toUtc().toIso8601String();
      }
      return input;
    },
  );
  final host = Platform.environment['POSTGRES_HOST'] ?? 'localhost';
  final port = Platform.environment['POSTGRES_PORT'] ?? '5432';
  final databaseName = Platform.environment['POSTGRES_DATABASE'] ?? 'postgres';
  final username = Platform.environment['POSTGRES_USERNAME'];
  final password = Platform.environment['POSTGRES_PASSWORD'];
  final endpoint = Endpoint(
    host: host,
    port: int.parse(port),
    database: databaseName,
    username: username,
    password: password,
  );

  await temp.initialize(
    endpoint: endpoint,
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );
  database = temp;
}

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) {
  return serve(handler, ip, port);
}
