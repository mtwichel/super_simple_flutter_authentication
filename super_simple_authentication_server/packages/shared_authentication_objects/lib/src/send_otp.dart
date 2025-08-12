import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:shared_authentication_objects/shared_authentication_objects.dart';

part 'send_otp.g.dart';

/// {@template send_otp_request}
/// The request body for sending an OTP.
/// {@endtemplate}
@JsonSerializable()
class SendOtpRequest extends Equatable {
  /// {@macro send_otp_request}
  const SendOtpRequest({required this.identifier, required this.type});

  /// Creates a [SendOtpRequest] from a JSON object.
  factory SendOtpRequest.fromJson(Map<String, dynamic> json) =>
      _$SendOtpRequestFromJson(json);

  /// Converts a [SendOtpRequest] to a JSON object.
  Map<String, dynamic> toJson() => _$SendOtpRequestToJson(this);

  /// The identifier to send the OTP to.
  final String identifier;

  /// The type of OTP to send.
  final OtpType type;

  @override
  List<Object> get props => [identifier, type];
}

/// {@template send_otp_response}
/// The response body for sending an OTP.
/// {@endtemplate}
@JsonSerializable()
class SendOtpResponse extends Equatable {
  /// {@macro send_otp_response}
  const SendOtpResponse({required this.expiresAt, required this.expiresIn});

  /// Creates a [SendOtpResponse] from a JSON object.
  factory SendOtpResponse.fromJson(Map<String, dynamic> json) =>
      _$SendOtpResponseFromJson(json);

  /// Converts a [SendOtpResponse] to a JSON object.
  Map<String, dynamic> toJson() => _$SendOtpResponseToJson(this);

  /// The date and time the OTP will expire.
  final DateTime expiresAt;

  /// The duration the OTP will expire in.
  final Duration expiresIn;

  @override
  List<Object> get props => [expiresAt, expiresIn];
}
