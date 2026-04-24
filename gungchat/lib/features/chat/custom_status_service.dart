class CustomStatusService {
  const CustomStatusService();

  static const int maxLength = 80;

  String normalize(String text) {
    final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= maxLength) {
      return compact;
    }

    return compact.substring(0, maxLength).trimRight();
  }

  String? normalizeNullable(String? text) {
    final normalized = normalize(text ?? '');
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}