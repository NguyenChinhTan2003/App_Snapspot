enum Flavor {
  dev,
  staging,
}

class F {
  static Flavor? appFlavor;

  static String get name => appFlavor?.name ?? '';

  static String get title {
    switch (appFlavor) {
      case Flavor.dev:
        return 'App Dev';
      case Flavor.staging:
        return 'App Staging';
      default:
        return 'title';
    }
  }

}
