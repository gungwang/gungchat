import 'package:flutter/foundation.dart';

@immutable
class SurveillanceCapabilityReport {
  const SurveillanceCapabilityReport({
    required this.screenshotProtectionSupported,
    required this.recordingDetectionSupported,
    required this.notes,
  });

  final bool screenshotProtectionSupported;
  final bool recordingDetectionSupported;
  final String notes;
}

class SurveillanceDetector {
  const SurveillanceDetector();

  Future<SurveillanceCapabilityReport> scanCapabilities() async {
    return const SurveillanceCapabilityReport(
      screenshotProtectionSupported: true,
      recordingDetectionSupported: false,
      notes:
          'Platform capability reporting is in place; process-level app blocking requires platform-specific code in later phases.',
    );
  }
}
