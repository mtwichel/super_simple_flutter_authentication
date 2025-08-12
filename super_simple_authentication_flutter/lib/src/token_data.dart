import 'dart:convert';

import 'package:equatable/equatable.dart';

/// {@template token_data}
/// The data associated with a token.
/// {@endtemplate}
class TokenData extends Equatable {
  /// {@macro token_data}
  const TokenData({
    required this.userId,
    required this.isNewUser,
  });

  /// Creates a [TokenData] from a JSON object.
  factory TokenData.fromToken(String token) {
    final [_, payload, _] = token.split('.');
    final paddingLength = (4 - (payload.length % 4)) % 4;
    final paddedPayload = payload + ('=' * paddingLength);
    final jsonString = utf8.decode(base64Url.decode(paddedPayload));
    final json = Map<String, dynamic>.from(jsonDecode(jsonString) as Map);
    return TokenData(
      userId: json['sub'] as String,
      isNewUser: json['new'] as bool,
    );
  }

  /// The user ID.
  final String userId;

  /// Whether the user is new.
  final bool isNewUser;

  @override
  List<Object?> get props => [userId, isNewUser];
}
