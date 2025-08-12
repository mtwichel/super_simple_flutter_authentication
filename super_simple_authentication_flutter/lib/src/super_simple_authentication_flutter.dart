import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_authentication_objects/shared_authentication_objects.dart';
import 'package:super_simple_authentication_flutter/super_simple_authentication_flutter.dart';

const _accessTokenKey = 'accessToken';
const _refreshTokenKey = 'refreshToken';

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
    bool secureSheme = true,
    int? port,
    String? basePath,
    FlutterSecureStorage? secureStorage,
  })  : _client = client ?? http.Client(),
        _secureSheme = secureSheme,
        _host = host,
        _port = port,
        _basePath = basePath,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final http.Client _client;
  final FlutterSecureStorage _secureStorage;

  final bool _secureSheme;
  final String _host;
  final int? _port;
  final String? _basePath;

  Uri _makeUri(
    String path, {
    Map<String, String> queryParameters = const {},
    String scheme = 'http',
  }) {
    return Uri(
      scheme: _secureSheme ? '${scheme}s' : scheme,
      host: _host,
      port: _port,
      path: _basePath != null ? '$_basePath$path' : path,
      queryParameters: queryParameters,
    );
  }

  Future<T> _makeRequest<T>(
    String path, {
    required String method,
    required FromJson<T> responseFromJson,
    Object? body,
    Map<String, String> headers = const {},
    Map<String, String> queryParameters = const {},
  }) async {
    final request = http.Request(
      method,
      _makeUri(path),
    );
    request.headers.addAll(headers);
    request.headers[HttpHeaders.contentTypeHeader] = 'application/json';
    if (body != null) {
      request.body = jsonEncode(body);
    }
    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    final json = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    return responseFromJson(json);
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
    final SignInWithEmailAndPasswordResponse(
      token: accessToken,
      :refreshToken,
      :error
    ) = await _makeRequest(
      '/auth/email-password/sign-in',
      method: 'POST',
      body: SignInWithEmailAndPasswordRequest(email: email, password: password),
      responseFromJson: SignInWithEmailAndPasswordResponse.fromJson,
    );

    if (error != null) {
      throw SignInException(error);
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
    final CreateAccountWithEmailAndPasswordResponse(
      token: accessToken,
      :refreshToken,
      :error
    ) = await _makeRequest(
      '/auth/email-password/create-account',
      method: 'POST',
      body: CreateAccountWithEmailAndPasswordRequest(
        email: email,
        password: password,
      ),
      responseFromJson: CreateAccountWithEmailAndPasswordResponse.fromJson,
    );
    if (error != null) {
      throw SignInException(error);
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
      '/auth/request-otp',
      method: 'POST',
      body: SendOtpRequest(identifier: email, type: OtpType.email),
      responseFromJson: SendOtpResponse.fromJson,
    );
  }

  /// Verify an OTP for the given [email].
  Future<void> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    final VerifyOtpResponse(token: accessToken, :refreshToken, :error) =
        await _makeRequest(
      '/auth/verify-otp',
      method: 'POST',
      body: VerifyOtpRequest(identifier: email, otp: otp, type: OtpType.email),
      responseFromJson: VerifyOtpResponse.fromJson,
    );
    if (error != null) {
      throw SignInException(error);
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
      '/auth/request-otp',
      method: 'POST',
      body: SendOtpRequest(identifier: phoneNumber, type: OtpType.phone),
      responseFromJson: SendOtpResponse.fromJson,
    );
  }

  /// Verify an OTP for the given [phoneNumber].
  Future<void> verifyPhoneOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final VerifyOtpResponse(token: accessToken, :refreshToken, :error) =
        await _makeRequest(
      '/auth/verify-otp',
      method: 'POST',
      body: VerifyOtpRequest(
        identifier: phoneNumber,
        otp: otp,
        type: OtpType.phone,
      ),
      responseFromJson: VerifyOtpResponse.fromJson,
    );
    if (error != null) {
      throw SignInException(error);
    }
    if (accessToken == null || refreshToken == null) {
      throw const SignInException(SignInError.unknown);
    }
    await _setNewToken(accessToken: accessToken, refreshToken: refreshToken);
  }

  /// Signs in a user with the given 3rd party[credential].
  Future<void> signInWithCredential(
    Credential credential,
  ) async {
    final SignInWithCredentialResponse(
      token: accessToken,
      :refreshToken,
      :error
    ) = await _makeRequest(
      '/auth/sign-in-with-credential',
      method: 'POST',
      body: SignInWithCredentialRequest(credential: credential),
      responseFromJson: SignInWithCredentialResponse.fromJson,
    );

    if (error != null) {
      throw SignInException(error);
    }
    if (accessToken == null || refreshToken == null) {
      throw const SignInException(SignInError.unknown);
    }
    await _setNewToken(accessToken: accessToken, refreshToken: refreshToken);
  }

  /// Signs in a user anonymously.
  Future<void> signInAnonymously() async {
    final SignInAnonymouslyResponse(token: accessToken, :refreshToken, :error) =
        await _makeRequest(
      '/auth/sign-in-anonymously',
      method: 'POST',
      responseFromJson: SignInAnonymouslyResponse.fromJson,
    );
    if (error != null) {
      throw SignInException(error);
    }
    if (accessToken == null || refreshToken == null) {
      throw const SignInException(SignInError.unknown);
    }
    await _setNewToken(accessToken: accessToken, refreshToken: refreshToken);
  }
}
