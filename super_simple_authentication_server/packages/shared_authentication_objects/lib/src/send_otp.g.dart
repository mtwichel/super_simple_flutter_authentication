// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_otp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SendOtpRequest _$SendOtpRequestFromJson(Map<String, dynamic> json) =>
    SendOtpRequest(
      identifier: json['identifier'] as String,
      type: $enumDecode(_$OtpTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$SendOtpRequestToJson(SendOtpRequest instance) =>
    <String, dynamic>{
      'identifier': instance.identifier,
      'type': _$OtpTypeEnumMap[instance.type]!,
    };

const _$OtpTypeEnumMap = {
  OtpType.email: 'email',
  OtpType.phone: 'phone',
};

SendOtpResponse _$SendOtpResponseFromJson(Map<String, dynamic> json) =>
    SendOtpResponse(
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      expiresIn: Duration(microseconds: (json['expiresIn'] as num).toInt()),
    );

Map<String, dynamic> _$SendOtpResponseToJson(SendOtpResponse instance) =>
    <String, dynamic>{
      'expiresAt': instance.expiresAt.toIso8601String(),
      'expiresIn': instance.expiresIn.inMicroseconds,
    };
