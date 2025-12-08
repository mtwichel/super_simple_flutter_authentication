import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:super_simple_authentication_toolkit/src/webauthn/webauthn_models.dart';

/// Client for communicating with an external WebAuthn verification service.
class WebAuthnServiceClient {
  /// Creates a new [WebAuthnServiceClient].
  WebAuthnServiceClient({
    required String baseUrl,
    String? apiKey,
    http.Client? client,
  }) : _baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl,
       _apiKey = apiKey,
       _client = client ?? http.Client();

  final String _baseUrl;
  final String? _apiKey;
  final http.Client _client;

  /// Gets registration options from the external service.
  ///
  /// [rpId] - Relying Party ID
  /// [rpName] - Relying Party name
  /// [origin] - Allowed origin
  /// [userId] - Optional user ID for existing users
  /// [userName] - Optional user name
  /// [userDisplayName] - Optional user display name
  Future<PublicKeyCredentialCreationOptions> getRegistrationOptions({
    required String rpId,
    required String rpName,
    required String origin,
    String? userId,
    String? userName,
    String? userDisplayName,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/register/options'),
      headers: _buildHeaders(),
      body: jsonEncode({
        'rpId': rpId,
        'rpName': rpName,
        'origin': origin,
        if (userId != null) 'userId': userId,
        if (userName != null) 'userName': userName,
        if (userDisplayName != null) 'userDisplayName': userDisplayName,
      }),
    );

    if (response.statusCode != HttpStatus.ok) {
      throw Exception(
        'Failed to get registration options: ${response.statusCode} ${response.body}',
      );
    }

    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  /// Verifies an attestation response from the client.
  ///
  /// Returns verification result with credential ID and user handle if successful.
  Future<WebAuthnVerificationResult> verifyAttestation({
    required AttestationResponse attestationResponse,
    required String rpId,
    required String origin,
    String? expectedChallenge,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/register/verify'),
      headers: _buildHeaders(),
      body: jsonEncode({
        'attestationResponse': attestationResponse,
        'rpId': rpId,
        'origin': origin,
        if (expectedChallenge != null) 'expectedChallenge': expectedChallenge,
      }),
    );

    if (response.statusCode != HttpStatus.ok) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (
        success: false,
        credentialId: null,
        userId: null,
        signCount: null,
        publicKey: '',
        error: body['error'] as String? ?? 'Verification failed',
      );
    }

    final result = jsonDecode(response.body) as Map<String, dynamic>;
    return (
      success: true,
      credentialId: result['credentialId'] as String?,
      userId: result['userId'] as String?,
      signCount: result['signCount'] as int? ?? 0,
      publicKey: result['publicKey'] as String? ?? '',
      error: null,
    );
  }

  /// Gets sign-in options from the external service.
  ///
  /// [rpId] - Relying Party ID
  /// [origin] - Allowed origin
  /// [allowCredentials] - Optional list of allowed credential IDs
  Future<PublicKeyCredentialRequestOptions> getSignInOptions({
    required String rpId,
    required String origin,
    List<String>? allowCredentials,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/signin/options'),
      headers: _buildHeaders(),
      body: jsonEncode({
        'rpId': rpId,
        'origin': origin,
        if (allowCredentials != null) 'allowCredentials': allowCredentials,
      }),
    );

    if (response.statusCode != HttpStatus.ok) {
      throw Exception(
        'Failed to get sign-in options: ${response.statusCode} ${response.body}',
      );
    }

    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  /// Verifies an assertion response from the client.
  ///
  /// Returns verification result with credential ID and sign count if successful.
  Future<WebAuthnVerificationResult> verifyAssertion({
    required AssertionResponse assertionResponse,
    required String rpId,
    required String origin,
    required String credentialId,
    required List<int> publicKey,
    required int expectedSignCount,
    String? expectedChallenge,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/signin/verify'),
      headers: _buildHeaders(),
      body: jsonEncode({
        'assertionResponse': assertionResponse,
        'rpId': rpId,
        'origin': origin,
        'credentialId': credentialId,
        'publicKey': base64Url.encode(publicKey),
        'expectedSignCount': expectedSignCount,
        if (expectedChallenge != null) 'expectedChallenge': expectedChallenge,
      }),
    );

    if (response.statusCode != HttpStatus.ok) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (
        success: false,
        credentialId: null,
        userId: null,
        signCount: null,
        publicKey: '',
        error: body['error'] as String? ?? 'Verification failed',
      );
    }

    final result = jsonDecode(response.body) as Map<String, dynamic>;
    return (
      success: true,
      credentialId: result['credentialId'] as String?,
      userId: result['userId'] as String?,
      signCount: result['signCount'] as int?,
      publicKey: '', // Not needed for assertion verification
      error: null,
    );
  }

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: ContentType.json.mimeType,
    };
    if (_apiKey != null) {
      headers['Authorization'] = 'Bearer $_apiKey';
      // Alternative: headers['X-API-Key'] = _apiKey;
    }
    return headers;
  }
}
