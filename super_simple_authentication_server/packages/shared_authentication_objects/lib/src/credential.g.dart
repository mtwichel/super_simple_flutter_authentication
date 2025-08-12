// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credential.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Credential _$CredentialFromJson(Map<String, dynamic> json) => Credential(
      type: $enumDecode(_$CredentialTypeEnumMap, json['type']),
      token: json['token'] as String,
    );

Map<String, dynamic> _$CredentialToJson(Credential instance) =>
    <String, dynamic>{
      'type': _$CredentialTypeEnumMap[instance.type]!,
      'token': instance.token,
    };

const _$CredentialTypeEnumMap = {
  CredentialType.google: 'google',
  CredentialType.apple: 'apple',
};
