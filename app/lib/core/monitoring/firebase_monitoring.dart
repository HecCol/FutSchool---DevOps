import 'dart:async';
import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart'
    show FlutterError, defaultTargetPlatform, kDebugMode, kIsWeb, TargetPlatform;

/// Firebase telemetry helpers. Monitoring failures never block app flows.
abstract final class FirebaseMonitoring {
  static bool get _supportsCrashlytics =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static void installCrashHandlers() {
    // Crashlytics is supported on Android and Apple platforms, not Flutter web.
    if (!_supportsCrashlytics) return;

    FlutterError.onError = (details) {
      unawaited(FirebaseCrashlytics.instance.recordFlutterFatalError(details));
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
      );
      return true;
    };
  }

  static Future<void> breadcrumb(String event) async {
    if (!_supportsCrashlytics) return;
    try {
      await FirebaseCrashlytics.instance.log(event);
    } catch (_) {
      // A telemetry outage must not interrupt authentication or data changes.
    }
  }

  /// Emits one sanitized non-fatal event only when explicitly enabled in debug.
  /// Run once with --dart-define=CRASHLYTICS_TEST_EVENT=true, then omit the flag.
  static Future<void> sendDebugTestEventIfRequested() async {
    const requested = bool.fromEnvironment(
      'CRASHLYTICS_TEST_EVENT',
      defaultValue: false,
    );
    if (!kDebugMode || !requested || !_supportsCrashlytics) return;

    try {
      await FirebaseCrashlytics.instance.recordError(
        StateError('Crashlytics integration test'),
        StackTrace.current,
        reason: 'Sanitized debug setup check',
        fatal: false,
      );
    } catch (_) {
      // A telemetry outage must not prevent app startup.
    }
  }

  static Future<T> trace<T>(String name, Future<T> Function() operation) async {
    Trace? trace;
    try {
      trace = FirebasePerformance.instance.newTrace(name);
      await trace.start();
    } catch (_) {
      trace = null;
    }

    var succeeded = false;
    try {
      final result = await operation();
      succeeded = true;
      return result;
    } finally {
      if (trace != null) {
        try {
          trace.putAttribute('result', succeeded ? 'success' : 'failure');
          await trace.stop();
        } catch (_) {
          // Preserve the result of the business operation if telemetry fails.
        }
      }
    }
  }
}
