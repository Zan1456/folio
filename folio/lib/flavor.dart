// Distribution flavor flag — set via --dart-define=FLAVOR=playstore
const String _kFlavor =
    String.fromEnvironment('FLAVOR', defaultValue: 'github');

/// true when built for Google Play Store — disables APK self-update
const bool kIsPlayStore = _kFlavor == 'playstore';
