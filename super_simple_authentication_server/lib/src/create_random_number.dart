import 'dart:math';

/// Generates a random number of the given length in bytes.
List<int> generateRandomNumber({int length = 32}) {
  final random = Random.secure();
  return List<int>.generate(length, (i) => random.nextInt(256));
}
