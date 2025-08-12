// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_in_anonymously.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignInAnonymouslyResponse _$SignInAnonymouslyResponseFromJson(
        Map<String, dynamic> json) =>
    SignInAnonymouslyResponse(
      token: json['token'] as String?,
      refreshToken: json['refreshToken'] as String?,
      error: $enumDecodeNullable(_$SignInErrorEnumMap, json['error']),
    );

Map<String, dynamic> _$SignInAnonymouslyResponseToJson(
        SignInAnonymouslyResponse instance) =>
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
