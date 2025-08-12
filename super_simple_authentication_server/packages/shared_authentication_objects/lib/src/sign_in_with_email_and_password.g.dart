// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_in_with_email_and_password.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignInWithEmailAndPasswordRequest _$SignInWithEmailAndPasswordRequestFromJson(
        Map<String, dynamic> json) =>
    SignInWithEmailAndPasswordRequest(
      email: json['email'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$SignInWithEmailAndPasswordRequestToJson(
        SignInWithEmailAndPasswordRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
    };

SignInWithEmailAndPasswordResponse _$SignInWithEmailAndPasswordResponseFromJson(
        Map<String, dynamic> json) =>
    SignInWithEmailAndPasswordResponse(
      token: json['token'] as String?,
      error: $enumDecodeNullable(_$SignInErrorEnumMap, json['error']),
      refreshToken: json['refreshToken'] as String?,
    );

Map<String, dynamic> _$SignInWithEmailAndPasswordResponseToJson(
        SignInWithEmailAndPasswordResponse instance) =>
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
