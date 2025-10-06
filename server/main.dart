import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:super_simple_authentication_hive_data_storage/super_simple_authentication_hive_data_storage.dart';
import 'package:super_simple_authentication_postgres_data_storage/super_simple_authentication_postgres_data_storage.dart';
import 'package:super_simple_authentication_toolkit/super_simple_authentication_toolkit.dart';

late DataStorage dataStorage;
late Logger logger;

Future<void> init(InternetAddress ip, int port) async {
  final environment = Platform.environment;
  final logLevel = environment['LOG_LEVEL']?.toLowerCase() ?? 'info';
  logger = Logger(level: Level.values.firstWhere((e) => e.name == logLevel));
  final dataStorageType =
      environment['DATA_STORAGE_TYPE']?.toLowerCase() ?? 'in_memory';

  if (dataStorageType == 'in_memory') {
    logger.info('Initializing In-Memory data storage');
    dataStorage = InMemoryDataStorage();
  }

  if (dataStorageType == 'hive') {
    logger.info('Initializing Hive data storage');
    final storage = HiveDataStorage();
    await storage.initialize(
      databasePath: Platform.environment['HIVE_DATA_PATH'],
    );
    dataStorage = storage;
  }

  if (dataStorageType == 'postgres') {
    logger.info('Initializing Postgres data storage');
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

    final shouldInitializeDatabaseSchema =
        Platform.environment['SHOULD_INITIALIZE_DATABASE_SCHEMA'] == 'true';
    logger.alert('Initializing Postgres schema');

    final storage = PostgresDataStorage();
    await storage.initialize(
      endpoint: endpoint,
      settings: const ConnectionSettings(sslMode: SslMode.disable),
      shouldInitializeDatabase: shouldInitializeDatabaseSchema,
    );
    dataStorage = storage;
  }
}

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) {
  return serve(handler, ip, port);
}
