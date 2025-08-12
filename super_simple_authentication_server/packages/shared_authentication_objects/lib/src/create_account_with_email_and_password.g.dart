// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_account_with_email_and_password.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateAccountWithEmailAndPasswordRequest
    _$CreateAccountWithEmailAndPasswordRequestFromJson(
            Map<String, dynamic> json) =>
        CreateAccountWithEmailAndPasswordRequest(
          email: json['email'] as String,
          password: json['password'] as String,
        );

Map<String, dynamic> _$CreateAccountWithEmailAndPasswordRequestToJson(
        CreateAccountWithEmailAndPasswordRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
    };

CreateAccountWithEmailAndPasswordResponse
    _$CreateAccountWithEmailAndPasswordResponseFromJson(
            Map<String, dynamic> json) =>
        CreateAccountWithEmailAndPasswordResponse(
          token: json['token'] as String?,
          refreshToken: json['refreshToken'] as String?,
          error: $enumDecodeNullable(_$SignInErrorEnumMap, json['error']),
        );

Map<String, dynamic> _$CreateAccountWithEmailAndPasswordResponseToJson(
        CreateAccountWithEmailAndPasswordResponse instance) =>
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
