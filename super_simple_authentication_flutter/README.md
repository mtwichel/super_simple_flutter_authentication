# Super Simple Authentication Flutter

A Flutter client package for Super Simple Authentication that provides easy-to-use authentication methods including email/password, OTP verification, third-party credentials, and anonymous sign-in.

## Features

- **Email/Password Authentication**: Sign in and create accounts with email and password
- **OTP Verification**: Send and verify one-time passwords via email or SMS
- **Third-party Sign-in**: Support for external authentication providers
- **Anonymous Sign-in**: Allow users to sign in without credentials
- **Secure Token Storage**: Automatic storage of access and refresh tokens using Flutter Secure Storage
- **Token Management**: Built-in token refresh and management
- **Stream-based State**: Real-time authentication state updates

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  super_simple_authentication_flutter:
    path: path/to/super_simple_authentication_flutter
```

## Setup

### 1. Initialize the Client

```dart
import 'package:api_client/api_client.dart';
import 'package:super_simple_authentication_flutter/super_simple_authentication_flutter.dart';

// Create an API client instance
final apiClient = ApiClient(baseUrl: 'https://your-auth-server.com');

// Create the authentication client
final auth = SuperSimpleAuthentication(client: apiClient);

// Initialize to load stored tokens
await auth.initialize();
```

### 2. Listen to Authentication State

```dart
// Listen to access token changes
auth.accessTokenStream.listen((token) {
  if (token != null) {
    print('User signed in');
  } else {
    print('User signed out');
  }
});

// Listen to token data changes
auth.tokenDataStream.listen((tokenData) {
  if (tokenData != null) {
    print('User ID: ${tokenData.userId}');
    print('Is new user: ${tokenData.isNewUser}');
  }
});
```

## Usage

### Email/Password Authentication

#### Sign In

```dart
try {
  await auth.signInWithEmailAndPassword(
    email: 'user@example.com',
    password: 'password123',
  );
  print('Sign in successful');
} on SignInException catch (e) {
  print('Sign in failed: ${e.error}');
}
```

#### Create Account

```dart
try {
  await auth.createAccountWithEmailAndPassword(
    email: 'user@example.com',
    password: 'password123',
  );
  print('Account created successfully');
} on SignInException catch (e) {
  print('Account creation failed: ${e.error}');
}
```

### OTP Authentication

#### Email OTP

```dart
// Send OTP to email
await auth.sendEmailOtp(email: 'user@example.com');

// Verify OTP
try {
  await auth.verifyEmailOtp(
    email: 'user@example.com',
    otp: '123456',
  );
  print('Email OTP verified successfully');
} on SignInException catch (e) {
  print('OTP verification failed: ${e.error}');
}
```

#### Phone OTP

```dart
// Send OTP to phone
await auth.sendPhoneOtp(phoneNumber: '+1234567890');

// Verify OTP
try {
  await auth.verifyPhoneOtp(
    phoneNumber: '+1234567890',
    otp: '123456',
  );
  print('Phone OTP verified successfully');
} on SignInException catch (e) {
  print('OTP verification failed: ${e.error}');
}
```

### Third-party Authentication

```dart
// Create a credential (example for Google)
final credential = Credential(
  type: CredentialType.google,
  token: 'google_id_token_here',
);

try {
  await auth.signInWithCredential(credential);
  print('Third-party sign in successful');
} on SignInException catch (e) {
  print('Third-party sign in failed: ${e.error}');
}
```

### Anonymous Sign-in

```dart
try {
  await auth.signInAnonymously();
  print('Anonymous sign in successful');
} on SignInException catch (e) {
  print('Anonymous sign in failed: ${e.error}');
}
```

### Sign Out

```dart
await auth.signOut();
print('User signed out');
```

### Check Authentication State

```dart
// Check if user is signed in
final isSignedIn = auth.accessToken != null;

// Get current token data
final tokenData = auth.tokenData;
if (tokenData != null) {
  print('Current user ID: ${tokenData.userId}');
  print('Is new user: ${tokenData.isNewUser}');
}
```

## Error Handling

The package throws `SignInException` for authentication errors. Handle them appropriately:

```dart
try {
  await auth.signInWithEmailAndPassword(
    email: 'user@example.com',
    password: 'wrongpassword',
  );
} on SignInException catch (e) {
  switch (e.error) {
    case SignInError.invalidCredentials:
      print('Invalid email or password');
      break;
    case SignInError.userNotFound:
      print('User not found');
      break;
    case SignInError.unknown:
      print('An unknown error occurred');
      break;
    // Handle other error cases
  }
}
```

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:super_simple_authentication_flutter/super_simple_authentication_flutter.dart';

class AuthService {
  static final _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  late final SuperSimpleAuthentication _auth;

  Future<void> initialize() async {
    final apiClient = ApiClient(baseUrl: 'https://your-auth-server.com');
    _auth = SuperSimpleAuthentication(client: apiClient);
    await _auth.initialize();
  }

  SuperSimpleAuthentication get auth => _auth;
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _authService = AuthService();
  bool _isSignedIn = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await _authService.initialize();

    // Listen to authentication state changes
    _authService.auth.accessTokenStream.listen((token) {
      setState(() {
        _isSignedIn = token != null;
      });
    });
  }

  Future<void> _signIn() async {
    try {
      await _authService.auth.signInWithEmailAndPassword(
        email: 'user@example.com',
        password: 'password123',
      );
    } on SignInException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed: ${e.error}')),
      );
    }
  }

  Future<void> _signOut() async {
    await _authService.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Super Simple Auth Demo')),
        body: Center(
          child: _isSignedIn
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Welcome! You are signed in.'),
                    ElevatedButton(
                      onPressed: _signOut,
                      child: Text('Sign Out'),
                    ),
                  ],
                )
              : ElevatedButton(
                  onPressed: _signIn,
                  child: Text('Sign In'),
                ),
        ),
      ),
    );
  }
}
```

## Dependencies

This package depends on:

- `api_client`: For making HTTP requests to the authentication server
- `flutter_secure_storage`: For secure token storage
- `shared_authentication_objects`: Shared data models and types
- `equatable`: For value equality comparisons

## License

This package is part of the Super Simple Authentication system.
