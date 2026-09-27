import 'package:flutter/foundation.dart';

/// Minimal structured logging abstraction (Phase 1, item 11).
///
/// Rules enforced here:
/// - Callers must NEVER pass credentials into a log call. Raw engine output
///   is passed through [redact] before logging so '/p:<password>' style
///   arguments can never leak into logs.
/// - Debug logging can be disabled via [debugEnabled].
/// - Release builds stay quiet for debug-level output.
class AppLog {
  AppLog._();

  /// Master switch for debug-level logging.
  static bool debugEnabled = true;

  /// Debug-level log. Suppressed in release builds and when disabled.
  static void d(String tag, String message) {
    if (debugEnabled && !kReleaseMode) {
      debugPrint('[$tag] $message');
    }
  }

  /// Warning-level log. Always emitted.
  static void w(String tag, String message) {
    debugPrint('[$tag] WARN: $message');
  }

  /// Error-level log. Always emitted.
  static void e(String tag, String message) {
    debugPrint('[$tag] ERROR: $message');
  }

  /// Masks FreeRDP password arguments ('/p:secret' -> '/p:********') so raw
  /// engine output can be logged safely.
  static String redact(String line) {
    return line.replaceAllMapped(
      RegExp(r'/p:\S+'),
      (_) => '/p:********',
    );
  }
}
