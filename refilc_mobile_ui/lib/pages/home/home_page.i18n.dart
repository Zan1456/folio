import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byLocale("hu-HU") +
      {
        "en-US": {
          "goodmorning": "Good morning, %s!",
          "goodafternoon": "Good afternoon, %s!",
          "goodevening": "Good evening, %s!",
          "goodnight": "Good night, %s!",
          "goodrest": "⛱️ Have a nice holiday, %s!",
          "happybirthday": "🎂 Happy birthday, %s!",
          "merryxmas": "🎄 Merry Christmas, %s!",
          "happynewyear": "🎉 Happy New Year, %s!",
          "refilcopen": "🎈 reFilc is 1 year old, %s!",
          "empty": "Nothing to see here.",
          "All": "All",
          "Grades": "Grades",
          "Exams": "Exams",
          "Messages": "Messages",
          "Absences": "Absences",
          "update_available": "Update Available",
          "missed_exams": "You missed %s exam(s) this week.",
          "missed_exam_contact": "Contact %s to resolve it!",
        },
        "hu-HU": {
          "goodmorning": "Jó reggelt, %s!",
          "goodafternoon": "Szép napot, %s!",
          "goodevening": "Szép estét, %s!",
          "goodnight": "Jó éjszakát, %s!",
          "goodrest": "⛱️ Jó szünetet, %s!",
          "happybirthday": "🎂 Boldog születésnapot, %s!",
          "merryxmas": "🎄 Boldog Karácsonyt, %s!",
          "happynewyear": "🎉 Boldog új évet, %s!",
          "refilcopen": "🎈 1 éves a reFilc, %s!",
          "empty": "Nincs itt semmi látnivaló.",
          "All": "Összes",
          "Grades": "Jegyek",
          "Exams": "Számonkérések",
          "Messages": "Üzenetek",
          "Absences": "Hiányzások",
          "update_available": "Frissítés elérhető",
          "missed_exams": "Ezen a héten hiányoztál %s számonkérésről.",
          "missed_exam_contact": "Keresd %s tanár urat/hölgyet, hogy pótold!",
        },
        "de-DE": {
          "goodmorning": "Guten morgen, %s!",
          "goodafternoon": "Guten Tag, %s!",
          "goodevening": "Guten Abend, %s!",
          "goodnight": "Gute Nacht, %s!",
          "goodrest": "⛱️ Schöne Ferien, %s!",
          "happybirthday": "🎂 Alles Gute zum Geburtstag, %s!",
          "merryxmas": "🎄 Frohe Weihnachten, %s!",
          "happynewyear": "🎉 Frohes neues Jahr, %s!",
          "refilcopen": "🎈 reFilc ist 1 Jahr alt, %s!",
          "empty": "Hier gibt es nichts zu sehen.",
          "All": "Alles",
          "Grades": "Noten",
          "Exams": "Aufsätze",
          "Messages": "Nachrichten",
          "Absences": "Fehlen",
          "update_available": "Update verfügbar",
          "missed_exams": "Diese Woche haben Sie %s Prüfungen verpasst.",
          "missed_exam_contact": "Wenden Sie sich an %s, um sie zu erneuern!",
        },
      };

  String get i18n => localize(this, _t);
  String fill(List<Object> params) => localizeFill(this, params);
  String plural(int value) => localizePlural(value, this, _t);
  String version(Object modifier) => localizeVersion(modifier, this, _t);
}

