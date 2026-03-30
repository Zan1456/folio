import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byLocale("hu-HU") +
      {
        "en-US": {
          "cancelled": "Cancelled lesson",
          "substituted": "Substituted lesson",
        },
        "hu-HU": {
          "cancelled": "Elmaradó óra",
          "substituted": "Helyettesített óra",
        },
        "de-DE": {
          "cancelled": "Abgesagte Stunde",
          "substituted": "Vertretene Stunden",
        }
      };

  String get i18n => localize(this, _t);
  String fill(List<Object> params) => localizeFill(this, params);
  String plural(int value) => localizePlural(value, this, _t);
  String version(Object modifier) => localizeVersion(modifier, this, _t);
}

