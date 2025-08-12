// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_in_with_credential.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignInWithCredentialRequest _$SignInWithCredentialRequestFromJson(
        Map<String, dynamic> json) =>
    SignInWithCredentialRequest(
      credential:
          Credential.fromJson(json['credential'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SignInWithCredentialRequestToJson(
        SignInWithCredentialRequest instance) =>
    <String, dynamic>{
      'credential': instance.credential,
    };

SignInWithCredentialResponse _$SignInWithCredentialResponseFromJson(
        Map<String, dynamic> json) =>
    SignInWithCredentialResponse(
      token: json['token'] as String?,
      refreshToken: json['refreshToken'] as String?,
      error: $enumDecodeNullable(_$SignInErrorEnumMap, json['error']),
    );

Map<String, dynamic> _$SignInWithCredentialResponseToJson(
        SignInWithCredentialResponse instance) =>
    <String, dynamic>{
      'token': instance.token,
      'refreshToken': instance.refreshToken,
      'error': _$SignInErrorEnumMap[instance.error],
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
