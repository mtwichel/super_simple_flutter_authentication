import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:super_simple_authentication_flutter/super_simple_authentication_flutter.dart';

const _accessTokenKey = 'accessToken';
const _refreshTokenKey = 'refreshToken';

/// A record of the paths for the endpoints of the Super Simple Authentication
typedef EndpointPaths = ({
  String signInWithEmailAndPassword,
  String createAccountWithEmailAndPassword,
  String sendEmailOtp,
  String verifyEmailOtp,
  String sendPhoneOtp,
  String verifyPhoneOtp,
  String signInWithCredential,
  String signInAnonymously,
  String refreshToken,
});

/// Converts a Map to a type
typedef FromJson<T> = T Function(Map<String, dynamic> json);

/// {@template super_simple_authentication}
/// A Flutter client for Super Simple Authentication.
/// {@endtemplate}
class SuperSimpleAuthentication {
  /// Creates a new instance of [SuperSimpleAuthentication].
  ///
  /// [secureStorage] is an optional secure storage instance for storing tokens.
  SuperSimpleAuthentication({
    required String host,
    http.Client? client,
    bool secureScheme = true,
    EndpointPaths endpointPaths = const (
      signInWithEmailAndPassword: '/sign-in/email-password',
      createAccountWithEmailAndPassword: '/create-account',
      sendEmailOtp: '/send-otp',
      verifyEmailOtp: '/sign-in/otp',
      sendPhoneOtp: '/send-otp',
      verifyPhoneOtp: '/sign-in/otp',
      signInWithCredential: '/sign-in/credential',
      signInAnonymously: '/sign-in/anonymously',
      refreshToken: '/refresh',
    ),
    int? port,
    String? basePath,
    FlutterSecureStorage? secureStorage,
  })  : _client = client ?? http.Client(),
        _secureScheme = secureScheme,
        _host = host,
        _port = port,
        _basePath = basePath,
        _endpointPaths = endpointPaths,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final http.Client _client;
  final FlutterSecureStorage _secureStorage;

  final bool _secureScheme;
  final String _host;
  final int? _port;
  final String? _basePath;
  final EndpointPaths _endpointPaths;

  Uri _makeUri(
    String path, {
    Map<String, String> queryParameters = const {},
    String scheme = 'http',
  }) {
    return Uri(
      scheme: _secureScheme ? '${scheme}s' : scheme,
      host: _host,
      port: _port,
      path: _basePath != null ? '$_basePath$path' : path,
      queryParameters: queryParameters,
    );
  }

  Future<Map<String, dynamic>> _makeRequest(
    String path, {
    required String method,
    Object? body,
    Map<String, String> headers = const {},
  }) async {
    final request = http.Request(
      method,
      _makeUri(path),
    );
    request.headers.addAll(headers);
    request.headers[HttpHeaders.contentTypeHeader] = ContentType.json.mimeType;
    if (body != null) {
      request.body = jsonEncode(body);
    }
    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  String? _accessToken;
  String? _refreshToken;

  final StreamController<String?> _accessTokenController =
      StreamController<String?>.broadcast();

  Future<void> _setNewToken({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _accessTokenController.add(_accessToken);
    await _secureStorage.write(
      key: _accessTokenKey,
      value: _accessToken,
    );
    await _secureStorage.write(
      key: _refreshTokenKey,
      value: _refreshToken,
    );
  }

  Future<void> _clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _accessTokenController.add(_accessToken);
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  /// A stream of the current access token, or null if not signed in.
  Stream<String?> get accessTokenStream => _accessTokenController.stream;

  /// The current access token, or null if not signed in.
  String? get accessToken => _accessToken;

  /// The current token data, or null if not signed in.
  TokenData? get tokenData =>
      _accessToken == null ? null : TokenData.fromToken(_accessToken!);

  /// A stream of the current token data, or null if not signed in.
  Stream<TokenData?> get tokenDataStream => _accessTokenController.stream
      .map((token) => token == null ? null : TokenData.fromToken(token));

  /// True if the user is signed in.
  bool get isSignedIn => _accessToken != null;

  /// Initializes the authentication client by loading tokens from secure
  /// storage.
  Future<void> initialize() async {
    _accessToken = await _secureStorage.read(key: _accessTokenKey);
    _refreshToken = await _secureStorage.read(key: _refreshTokenKey);
  }

  /// Signs out the current user and removes tokens from secure storage.
  Future<void> signOut() => _clearTokens();

  /// Signs in a user with the given [email] and [password].
  ///
  /// Stores the access and refresh tokens on success.
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final {
      'token': String? accessToken,
      'refreshToken': String? refreshToken,
      'error': String? error,
    } = await _makeRequest(
      _endpointPaths.signInWithEmailAndPassword,
      method: 'POST',
      body: {'email': email, 'password': password},
    );

    if (error != null) {
      throw SignInException(SignInError.values.byName(error));
    }
    if (accessToken == null || refreshToken == null) {
      throw const SignInException(SignInError.unknown);
    }
    await _setNewToken(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  /// Signs up a new user with the given [email] and [password].
  ///
  /// Stores the access and refresh tokens on success.
  Future<void> createAccountWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final {
      'token': String? accessToken,
      'refreshToken': String? refreshToken,
      'error': String? error,
    } = await _makeRequest(
      _endpointPaths.createAccountWithEmailAndPassword,
      method: 'POST',
      body: {'email': email, 'password': password},
    );
    if (error != null) {
      throw SignInException(SignInError.values.byName(error));
    }
    if (accessToken == null || refreshToken == null) {
      throw const SignInException(SignInError.unknown);
    }
    await _setNewToken(accessToken: accessToken, refreshToken: refreshToken);
  }

  /// Sends an OTP to the given [email].
  Future<void> sendEmailOtp({
    required String email,
  }) async {
    await _makeRequest(
      _endpointPaths.sendEmailOtp,
      method: 'POST',
      body: {'identifier': email, 'type': 'email'},
    );
  }

  /// Verify an OTP for the given [email].
  Future<void> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    final {
      'token': String? accessToken,
      'refreshToken': String? refreshToken,
      'error': String? error,
    } = await _makeRequest(
      _endpointPaths.verifyEmailOtp,
      method: 'POST',
      body: {'identifier': email, 'otp': otp, 'type': 'email'},
    );
    if (error != null) {
      throw SignInException(SignInError.values.byName(error));
    }
    if (accessToken == null || refreshToken == null) {
      throw const SignInException(SignInError.unknown);
    }
    await _setNewToken(accessToken: accessToken, refreshToken: refreshToken);
  }

  /// Sends an OTP to the given [phoneNumber].
  Future<void> sendPhoneOtp({
    required String phoneNumber,
  }) async {
    await _makeRequest(
      _endpointPaths.sendPhoneOtp,
      method: 'POST',
      body: {'identifier': phoneNumber, 'type': 'phone'},
    );
  }

  /// Verify an OTP for the given [phoneNumber].
  Future<void> verifyPhoneOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final {
      'token': String? accessToken,
      'refreshToken': String? refreshToken,
      'error': String? error,
    } = await _makeRequest(
      _endpointPaths.verifyPhoneOtp,
      method: 'POST',
      body: {'identifier': phoneNumber, 'otp': otp, 'type': 'phone'},
    );
    if (error != null) {
      throw SignInException(SignInError.values.byName(error));
    }
    if (accessToken == null || refreshToken == null) {
      throw const SignInException(SignInError.unknown);
    }
    await _setNewToken(accessToken: accessToken, refreshToken: refreshToken);
  }

  /// Signs in a user with the given 3rd party[credential].
  Future<void> signInWithCredential(
    String credential,
  ) async {
    final {
      'token': String? accessToken,
      'refreshToken': String? refreshToken,
      'error': String? error,
    } = await _makeRequest(
      _endpointPaths.signInWithCredential,
      method: 'POST',
      body: {'credential': credential},
    );

    if (error != null) {
      throw SignInException(SignInError.values.byName(error));
    }
    if (accessToken == null || refreshToken == null) {
      throw const SignInException(SignInError.unknown);
    }
    await _setNewToken(accessToken: accessToken, refreshToken: refreshToken);
  }

  /// Signs in a user anonymously.
  Future<void> signInAnonymously() async {
    final {
      'token': String? accessToken,
      'refreshToken': String? refreshToken,
      'error': String? error,
    } = await _makeRequest(
      _endpointPaths.signInAnonymously,
      method: 'POST',
      body: {},
    );
    if (error != null) {
      throw SignInException(SignInError.values.byName(error));
    }
    if (accessToken == null || refreshToken == null) {
      throw const SignInException(SignInError.unknown);
    }
    await _setNewToken(accessToken: accessToken, refreshToken: refreshToken);
  }
}
