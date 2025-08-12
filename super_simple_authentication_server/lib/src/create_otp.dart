import 'dart:math';

/// Creates a random OTP.
String createOtp({int length = 6}) {
  final otp = StringBuffer();
  final random = Random();
  for (var i = 0; i < length; i++) {
    otp.write(random.nextInt(10));
  }
  return otp.toString();
}
