// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_otp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerifyOtpRequest _$VerifyOtpRequestFromJson(Map<String, dynamic> json) =>
    VerifyOtpRequest(
      otp: json['otp'] as String,
      identifier: json['identifier'] as String,
      type: $enumDecode(_$OtpTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$VerifyOtpRequestToJson(VerifyOtpRequest instance) =>
    <String, dynamic>{
      'otp': instance.otp,
      'identifier': instance.identifier,
      'type': _$OtpTypeEnumMap[instance.type]!,
    };

const _$OtpTypeEnumMap = {
  OtpType.email: 'email',
  OtpType.phone: 'phone',
};

VerifyOtpResponse _$VerifyOtpResponseFromJson(Map<String, dynamic> json) =>
    VerifyOtpResponse(
      token: json['token'] as String?,
      error: $enumDecodeNullable(_$SignInErrorEnumMap, json['error']),
      refreshToken: json['refreshToken'] as String?,
    );

Map<String, dynamic> _$VerifyOtpResponseToJson(VerifyOtpResponse instance) =>
    <String, dynamic>{
      'token': instance.token,
      'error': _$SignInErrorEnumMap[instance.error],
      'refreshToken': instance.refreshToken,
    };

const _$SignInErrorEnumMap = {
  SignInError.invalidCredentials: 'invalidCredentials',
  SignInError.userNotFound: 'userNotFound',
  SignInError.serverError: 'serverError',
  SignInError.otpInvalid: 'otpInvalid',
  SignInError.invalid3rdPartyCredential: 'invalid3rdPartyCredential',
  SignInError.aborted: 'aborted',
  SignInError.unknown: 'unknown',
};
