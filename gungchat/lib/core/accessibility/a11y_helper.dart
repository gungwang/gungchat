import 'dart:async';
import 'dart:ui' show FlutterView;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class A11yHelper {
  const A11yHelper._();

  static const BoxConstraints minimumTouchTarget = BoxConstraints(
    minWidth: 48,
    minHeight: 48,
  );

  static bool prefersReducedMotion(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    return mediaQuery?.disableAnimations ?? false;
  }

  static bool isHighContrast(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    return mediaQuery?.highContrast ?? false;
  }

  static Future<void> announceWithView({
    required FlutterView view,
    required String message,
    required TextDirection direction,
  }) {
    return SemanticsService.sendAnnouncement(view, message, direction);
  }

  static void announce(String message, BuildContext context) {
    final direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
    final view = View.maybeOf(context);
    if (view == null) {
      return;
    }
    unawaited(
      announceWithView(
        view: view,
        message: message,
        direction: direction,
      ),
    );
  }
}