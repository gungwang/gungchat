enum SensitiveContentMode {
  standard,
  hardened,
}

class AppShield {
  const AppShield();

  bool get canBlockThirdPartyApps => false;

  Future<SensitiveContentMode> activateSensitiveMode() async {
    return SensitiveContentMode.hardened;
  }
}
