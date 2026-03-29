import 'package:i18n_extension/i18n_extension.dart';

extension ScreensLocalization on String {
  static final _t = Translations.byLocale("hu-HU") +
      {
        "en-US": {
          "home": "Home",
          "grades": "Grades",
          "timetable": "Timetable",
          "messages": "Messages",
          "absences": "Absences",
          "notes": "Notes",
          "more": "More",
          "profile": "Profile",
          "settings": "Settings",
        },
        "hu-HU": {
          "home": "Kezdőlap",
          "grades": "Jegyek",
          "timetable": "Órarend",
          "messages": "Üzenetek",
          "absences": "Hiányzások",
          "notes": "Jegyzetek",
          "more": "Több",
          "profile": "Profil",
          "settings": "Beállítások",
        },
        "de-DE": {
          "home": "Zuhause",
          "grades": "Noten",
          "timetable": "Zeitplan",
          "messages": "Mitteilungen",
          "absences": "Fehlen",
          "notes": "Anmerkungen",
          "more": "Mehr",
          "profile": "Profil",
          "settings": "Einstellungen",
        },
      };

  String get i18n => localize(this, _t);
  String fill(List<Object> params) => localizeFill(this, params);
  String plural(int value) => localizePlural(value, this, _t);
  String version(Object modifier) => localizeVersion(modifier, this, _t);
}

