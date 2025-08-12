import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_authentication_objects/shared_authentication_objects.dart';
import 'package:super_simple_authentication_flutter/super_simple_authentication_flutter.dart';

const _accessTokenKey = 'accessToken';
const _refreshTokenKey = 'refreshToken';

/// {@template super_simple_authentication}
/// A Flutter client for Super Simple Authentication.
/// {@endtemplate}
class SuperSimpleAuthentication {
  /// Creates a new instance of [SuperSimpleAuthentication].
  ///
  /// [secureStorage] is an optional secure storage instance for storing tokens.
  SuperSimpleAuthentication({
    required ApiClient client,
    FlutterSecureStorage? secureStorage,
  })  : _client = client,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final ApiClient _client;
  final FlutterSecureStorage _secureStorage;

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
    ) = await _client.post(
      '/auth/email-password/sign-in',
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
    ) = await _client.post(
      '/auth/email-password/create-account',
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
    await _client.post(
      '/auth/request-otp',
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
        await _client.post(
      '/auth/verify-otp',
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
    await _client.post(
      '/auth/request-otp',
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
        await _client.post(
      '/auth/verify-otp',
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
    ) = await _client.post(
      '/auth/sign-in-with-credential',
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
        await _client.post(
      '/auth/sign-in-anonymously',
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
