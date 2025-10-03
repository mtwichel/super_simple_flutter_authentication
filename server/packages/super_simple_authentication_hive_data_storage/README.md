# Super Simple Authentication Hive Data Storage

A Hive-based implementation of the `DataStorage` interface for [Super Simple Authentication](https://github.com/mtwichel/super_simple_flutter_authentication). This package provides persistent storage for authentication data using [Hive](https://pub.dev/packages/hive_ce), a lightweight and fast key-value database.

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  super_simple_authentication_hive_data_storage: ^0.0.1-dev.1
```

## Usage

### Basic Usage

Create an instance of `HiveDataStorage` and initialize it before using it with your authentication server:

```dart
import 'package:super_simple_authentication_hive_data_storage/super_simple_authentication_hive_data_storage.dart';

void main() async {
  final dataStorage = HiveDataStorage();

  // Initialize the database
  await dataStorage.initialize(
    databaseName: 'super_simple_authentication',
    databasePath: './data', // Optional: specify storage path
  );

  // Use with your authentication server
  // ...
}
```

### Auto-Initialize Constructor

For convenience, you can use the `autoInitialize` constructor which initializes the database immediately:

```dart
final dataStorage = HiveDataStorage.autoInitialize(
  databaseName: 'super_simple_authentication',
  databasePath: './data', // Optional
  encryptionKey: null, // Optional: HiveCipher for encryption
);
```

### Configuration Options

- **`databaseName`**: The name of the Hive box (default: `'super_simple_authentication'`)
- **`databasePath`**: The directory path where the database file will be stored (optional)
- **`encryptionKey`**: A `HiveCipher` for encrypting the database at rest (optional, but recommended for production)

### With Encryption

For production environments, it's recommended to use encryption:

```dart
import 'package:hive_ce/hive.dart';

// Generate a secure 256-bit encryption key
final secureKey = Hive.generateSecureKey();
final encryptionCipher = HiveAesCipher(secureKey);

final dataStorage = HiveDataStorage.autoInitialize(
  databaseName: 'super_simple_authentication',
  databasePath: './data',
  encryptionKey: encryptionCipher,
);
```

## Features

This storage implementation handles:

- User account creation and retrieval
- Session management
- Refresh token storage and revocation
- OTP generation and validation
- Email and phone number indexing

## Example with Server

```dart
import 'package:dart_frog/dart_frog.dart';
import 'package:super_simple_authentication_hive_data_storage/super_simple_authentication_hive_data_storage.dart';
import 'package:super_simple_authentication_toolkit/super_simple_authentication_toolkit.dart';

Future<void> init() async {
  // Initialize Hive data storage
  final dataStorage = HiveDataStorage.autoInitialize(
    databasePath: './data',
  );

  // Use with authentication middleware
  final authMiddleware = authenticationMiddleware(
    dataStorage: dataStorage,
    // ... other configuration
  );
}
```

## Learn More

- [Super Simple Authentication](https://github.com/mtwichel/super_simple_flutter_authentication)
- [Hive Documentation](https://docs.hivedb.dev/)
