import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byLocale("hu-HU") +
      {
        "en-US": {
          "me": "me",
          "to": "to",
        },
        "hu-HU": {
          "me": "én",
          "to": "Címzett:",
        },
        "de-DE": {
          "me": "mich",
          "to": "zu",
        }
      };

  String get i18n => localize(this, _t);
  String fill(List<Object> params) => localizeFill(this, params);
  String plural(int value) => localizePlural(value, this, _t);
  String version(Object modifier) => localizeVersion(modifier, this, _t);
}

