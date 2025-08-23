import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres_builder/postgres_builder.dart';
import 'package:super_simple_authentication_server/src/data_storage/data_storage.dart';
import 'package:super_simple_authentication_server/src/data_storage/hive_data_storage.dart';
import 'package:super_simple_authentication_server/src/data_storage/in_memory_data_storage.dart';
import 'package:super_simple_authentication_server/src/data_storage/postgres_data_storage.dart';

late DataStorage dataStorage;

Future<void> init(InternetAddress ip, int port) async {
  final environment = Platform.environment;
  final dataStorageType =
      environment['DATA_STORAGE_TYPE']?.toLowerCase() ?? 'in_memory';

  if (dataStorageType == 'in_memory') {
    dataStorage = InMemoryDataStorage();
  }

  if (dataStorageType == 'hive') {
    final storage = HiveDataStorage();
    await storage.initialize(
      databasePath: Platform.environment['HIVE_DATA_PATH'],
    );
    dataStorage = storage;
  }

  if (dataStorageType == 'postgres') {
    final host = Platform.environment['POSTGRES_HOST'] ?? 'localhost';
    final port = Platform.environment['POSTGRES_PORT'] ?? '5432';
    final databaseName =
        Platform.environment['POSTGRES_DATABASE'] ?? 'postgres';
    final username = Platform.environment['POSTGRES_USERNAME'];
    final password = Platform.environment['POSTGRES_PASSWORD'];
    final endpoint = Endpoint(
      host: host,
      port: int.parse(port),
      database: databaseName,
      username: username,
      password: password,
    );

    final database = DirectPostgresBuilder(
      debug: true,
      logger: (sql) {
        // ignore: avoid_print
        print(sql);
      },
    );

    await database.initialize(
      endpoint: endpoint,
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );

    final storage = PostgresDataStorage(database);
    dataStorage = storage;
  }
}

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) {
  return serve(handler, ip, port);
}
