import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:shared_authentication_objects/shared_authentication_objects.dart';

part 'verify_otp.g.dart';

/// {@template verify_otp_request}
/// A request to verify an OTP.
/// {@endtemplate}
@JsonSerializable()
class VerifyOtpRequest extends Equatable {
  /// {@macro verify_otp_request}
  const VerifyOtpRequest({
    required this.otp,
    required this.identifier,
    required this.type,
  });

  /// Creates a [VerifyOtpRequest] from a JSON object.
  factory VerifyOtpRequest.fromJson(Map<String, dynamic> json) =>
      _$VerifyOtpRequestFromJson(json);

  /// Converts a [VerifyOtpRequest] to a JSON object.
  Map<String, dynamic> toJson() => _$VerifyOtpRequestToJson(this);

  /// The OTP to verify.
  final String otp;

  /// The identifier to verify.
  final String identifier;

  /// The type of OTP to verify.
  final OtpType type;

  @override
  List<Object> get props => [otp, identifier, type];
}

/// {@template verify_otp_response}
/// A response to a verify OTP request.
/// {@endtemplate}
@JsonSerializable()
class VerifyOtpResponse extends Equatable {
  /// {@macro verify_otp_response}
  const VerifyOtpResponse({
    required this.token,
    required this.error,
    required this.refreshToken,
  });

  /// Creates a [VerifyOtpResponse] from a JSON object.
  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) =>
      _$VerifyOtpResponseFromJson(json);

  /// Converts a [VerifyOtpResponse] to a JSON object.
  Map<String, dynamic> toJson() => _$VerifyOtpResponseToJson(this);

  /// The token of the account.
  final String? token;

  /// The error that occurred.
  final SignInError? error;

  /// The refresh token of the account.
  final String? refreshToken;

  @override
  List<Object?> get props => [token, error, refreshToken];
}
