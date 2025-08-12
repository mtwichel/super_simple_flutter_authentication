// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refresh_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RefreshTokenRequest _$RefreshTokenRequestFromJson(Map<String, dynamic> json) =>
    RefreshTokenRequest(
      refreshToken: json['refreshToken'] as String,
    );

Map<String, dynamic> _$RefreshTokenRequestToJson(
        RefreshTokenRequest instance) =>
    <String, dynamic>{
      'refreshToken': instance.refreshToken,
    };

RefreshTokenResponse _$RefreshTokenResponseFromJson(
        Map<String, dynamic> json) =>
    RefreshTokenResponse(
      token: json['token'] as String?,
      refreshToken: json['refreshToken'] as String?,
      error: $enumDecodeNullable(_$RefreshTokenErrorEnumMap, json['error']),
    );

Map<String, dynamic> _$RefreshTokenResponseToJson(
        RefreshTokenResponse instance) =>
    <String, dynamic>{
      'token': instance.token,
      'refreshToken': instance.refreshToken,
      'error': _$RefreshTokenErrorEnumMap[instance.error],
    };

const _$RefreshTokenErrorEnumMap = {
  RefreshTokenError.revoked: 'revoked',
  RefreshTokenError.invalid: 'invalid',
  RefreshTokenError.unknown: 'unknown',
};
