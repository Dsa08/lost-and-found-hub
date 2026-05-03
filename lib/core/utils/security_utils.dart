import 'dart:convert';
import 'package:crypto/crypto.dart';

class SecurityUtils {
  SecurityUtils._();

  /// Hash jawaban security question dengan SHA-256.
  /// Input dinormalisasi: lowercase + trim whitespace
  static String hashAnswer(String answer) {
    final normalized = answer.toLowerCase().trim();
    final bytes = utf8.encode(normalized);
    return sha256.convert(bytes).toString();
  }

  /// Verifikasi jawaban user terhadap hash yang tersimpan di Firestore
  static bool verifyAnswer(String inputAnswer, String storedHash) {
    return hashAnswer(inputAnswer) == storedHash;
  }
}