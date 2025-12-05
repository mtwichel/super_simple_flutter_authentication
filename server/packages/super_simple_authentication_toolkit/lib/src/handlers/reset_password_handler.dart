import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:super_simple_authentication_toolkit/super_simple_authentication_toolkit.dart';

/// A handler for resetting a password using a password reset token.
Handler resetPasswordHandler() {
  return (context) async {
    if (context.request.method != HttpMethod.post) {
      return Response(statusCode: HttpStatus.methodNotAllowed);
    }
    final {'token': String token, 'password': String password} = await context
        .request
        .map();

    // Validate password is provided and not empty
    if (password.isEmpty) {
      return Response.json(
        body: PasswordResetResponse(
          error: PasswordResetError.unknown,
        ),
      );
    }

    final dataStorage = context.read<DataStorage>();
    final now = context.read<Now>();

    // Hash token before lookup since we store hashed tokens
    final tokenResult = await dataStorage.getPasswordResetToken(
      token: token,
      now: now.toIso8601String(),
    );

    // Security best practice: Don't reveal if token is invalid vs expired
    // Return generic error for both cases
    if (tokenResult.userId == null) {
      return Response.json(
        body: PasswordResetResponse(
          error: PasswordResetError.invalidToken,
        ),
      );
    }

    final userId = tokenResult.userId!;

    // Hash the new password with a new salt
    final hashedPassword = await calculatePasswordHash(password);

    // Update user's password and salt
    await dataStorage.updateUserPassword(
      userId: userId,
      hashedPassword: base64.encode(hashedPassword.hash),
      salt: base64.encode(hashedPassword.salt),
    );

    // Revoke all password reset tokens for this user (one-time use + security)
    await dataStorage.revokePasswordResetTokens(userId: userId);

    return Response.json(
      body: PasswordResetResponse(
        success: true,
      ),
    );
  };
}
