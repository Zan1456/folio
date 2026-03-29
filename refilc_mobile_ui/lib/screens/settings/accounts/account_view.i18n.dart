import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byLocale("hu-HU") +
      {
        "en-US": {
          "birthdate": "Birth date",
          "school": "School",
          "class": "Class",
          "address": "Home address",
          "parents": "Parent(s)",
          "parents_phone": "Parents' phone number: ",
          "grade-DElay": "Grade visibility delay",
          "hrs": "%s hour(s)",
        },
        "hu-HU": {
          "birthdate": "Születési dátum",
          "school": "Iskola",
          "class": "Osztály",
          "address": "Lakcím",
          "parents": "Szülő(k)",
          "grade-DElay": "Jegy megjelenítési késleltetés",
          "hrs": "%s óra",
        },
        "de-DE": {
          "birthdate": "Geburtsdatum",
          "school": "Schule",
          "class": "Klasse",
          "address": "Wohnanschrift",
          "parents": "Elter(n)",
          "grade-DElay": "Notenverzögerung",
          "hrs": "%s Stunde(n)",
        },
      };

  String get i18n => localize(this, _t);
  String fill(List<Object> params) => localizeFill(this, params);
  String plural(int value) => localizePlural(value, this, _t);
  String version(Object modifier) => localizeVersion(modifier, this, _t);
}

