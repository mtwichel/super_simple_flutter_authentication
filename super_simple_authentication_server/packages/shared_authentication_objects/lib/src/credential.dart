import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'credential.g.dart';

/// {@template credential}
/// A credential is a way to authenticate a user.
/// {@endtemplate}
@JsonSerializable()
class Credential extends Equatable {
  /// {@macro credential}
  const Credential({required this.type, required this.token});

  /// Converts a JSON object to a [Credential] object.
  factory Credential.fromJson(Map<String, dynamic> json) =>
      _$CredentialFromJson(json);

  /// Converts a [Credential] object to a JSON object.
  Map<String, dynamic> toJson() => _$CredentialToJson(this);

  /// The type of credential.
  final CredentialType type;

  /// The token for the credential.
  final String token;

  @override
  List<Object> get props => [type, token];
}

/// {@template credential_type}
/// The type of credential.
/// {@endtemplate}
enum CredentialType {
  /// Credential for sign in with Google.
  google,

  /// Credential for sign in with Apple.
  apple,
}
