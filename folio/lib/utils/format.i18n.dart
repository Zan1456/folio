import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byLocale("hu-HU") +
      {
        "en-US": {
          "Today": "Today",
          "Yesterday": "Yesterday",
          "Tomorrow": "Tomorrow",
        },
        "hu-HU": {
          "Today": "Ma",
          "Yesterday": "Tegnap",
          "Tomorrow": "Holnap",
        },
        "de-DE": {
          "Today": "Heute",
          "Yesterday": "Gestern",
          "Tomorrow": "Morgen",
        }
      };

  String get i18n => localize(this, _t);
  String fill(List<Object> params) => localizeFill(this, params);
  String plural(int value) => localizePlural(value, this, _t);
  String version(Object modifier) => localizeVersion(modifier, this, _t);
}


