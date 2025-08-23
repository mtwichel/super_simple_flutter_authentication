/// An error that occurred when signing in.
enum SignInError {
  /// The credentials provided were invalid.
  invalidCredentials,

  /// The user was not found.
  userNotFound,

  /// The OTP provided was invalid.
  otpInvalid,

  /// An unknown error occurred.
  unknown,

  /// The 3rd party credential provided was invalid.
  invalid3rdPartyCredential,
}
