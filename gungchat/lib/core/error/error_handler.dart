import 'package:flutter/foundation.dart';

class ErrorHandler {
  const ErrorHandler();

  Future<T?> guardAsync<T>(
    Future<T> Function() operation, {
    required String context,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      report(error, stackTrace, context: context);
      return null;
    }
  }

  void report(
    Object error,
    StackTrace stackTrace, {
    required String context,
  }) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'gungchat',
        context: ErrorDescription(context),
      ),
    );
  }
}
