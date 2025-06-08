// lib/utils/uuid_utils.dart
import 'package:uuid/uuid.dart';

class UUIDUtils {
  static const _uuid = Uuid();
  
  /// Validates if a string is a proper UUID
  static bool isValid(String? uuid) {
    if (uuid == null) return false;
    try {
      Uuid.parse(uuid);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Generates a new v4 UUID
  static String generate() => _uuid.v4();

  /// Parses a UUID string to ensure proper formatting
  static String parse(String uuid) {
    if (!isValid(uuid)) throw FormatException('Invalid UUID string');
    return Uuid.parse(uuid).toString();
  }
}