/// Build-time navigation workflow (`demo` | `production`).
enum NavigationMode {
  demo,
  production;

  static NavigationMode fromEnvironment() {
    const raw = String.fromEnvironment('NAVIGATION_MODE', defaultValue: 'demo');
    return raw.toLowerCase() == 'production'
        ? NavigationMode.production
        : NavigationMode.demo;
  }

  bool get isDemo => this == NavigationMode.demo;
  bool get isProduction => this == NavigationMode.production;
}
