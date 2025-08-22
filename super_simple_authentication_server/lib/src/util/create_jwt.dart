import 'package:super_simple_authentication_server/src/util/util.dart';

/// Creates a JWT for the given user.
Future<String> createJwt({
  required bool? isNewUser,
  required Map<String, String> environment,
  Duration validFor = const Duration(hours: 1),
  Duration notBefore = Duration.zero,
  String? audience,
  String? subject,
  String? issuer,
  String? secretKey,
  Map<String, dynamic> additionalClaims = const {},
}) async {
  final isAsymmetric = environment['JWT_HASHING_STRATEGY'] == 'asymmetric';

  if (isAsymmetric) {
    return createAsymmetricJwt(
      isNewUser: isNewUser,
      validFor: validFor,
      notBefore: notBefore,
      audience: audience,
      subject: subject,
      issuer: issuer,
      additionalClaims: additionalClaims,
      jwksUrl: environment['JWT_RSA_PUBLIC_KEY_URL'],
    );
  } else {
    final secretKey = environment['JWT_SECRET_KEY'];
    if (secretKey == null) {
      throw Exception('JWT_SECRET_KEY is not set');
    }
    return createSymmetricJwt(
      isNewUser: isNewUser,
      validFor: validFor,
      notBefore: notBefore,
      audience: audience,
      subject: subject,
      issuer: issuer,
      additionalClaims: additionalClaims,
      secretKey: secretKey,
    );
  }
}
