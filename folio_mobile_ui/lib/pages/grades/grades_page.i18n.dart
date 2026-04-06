import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byLocale("hu-HU") +
      {
        "en-US": {
          "page_title_grades": "Grades",
          "subjects_tab": "Subjects",
          "grades_tab": "Grades",
          "Grades": "Grades",
          "Ghost Grades": "Ghost Grades",
          "annual_average": "Annual",
          "3_months_average": "3 Months",
          "30_days_average": "Monthly",
          "14_days_average": "2 Weeks",
          "7_days_average": "Weekly",
          "stats": "Stats",
          "grades_cnt": "Grades: %s",
          "grade_calc": "Calculator",
          "calc_mode": "Calc mode",
          "select_subject": "Select a subject",
          "empty": "No subjects yet.",
        },
        "hu-HU": {
          "page_title_grades": "Jegyek",
          "subjects_tab": "Tantárgyak",
          "grades_tab": "Jegyek",
          "Grades": "Jegyek",
          "Ghost Grades": "Szellem jegyek",
          "annual_average": "Éves",
          "3_months_average": "3 hónap",
          "30_days_average": "Havi",
          "14_days_average": "2 hetes",
          "7_days_average": "Heti",
          "stats": "Statisztika",
          "grades_cnt": "Jegyek: %s",
          "grade_calc": "Kalkulátor",
          "calc_mode": "Kalkulátor",
          "select_subject": "Válassz tantárgyat",
          "empty": "Még nincs tárgyad.",
        },
        "de-DE": {
          "page_title_grades": "Noten",
          "subjects_tab": "Fächer",
          "grades_tab": "Noten",
          "Grades": "Noten",
          "Ghost Grades": "Geist Noten",
          "annual_average": "Jährlich",
          "3_months_average": "3 Monate",
          "30_days_average": "Monatlich",
          "14_days_average": "2 Wochen",
          "7_days_average": "Wöchentlich",
          "stats": "Statistiken",
          "grades_cnt": "Noten: %s",
          "grade_calc": "Rechner",
          "calc_mode": "Rechner",
          "select_subject": "Fach auswählen",
          "empty": "Noch keine Fächer.",
        },
      };

  String get i18n => localize(this, _t);
  String fill(List<Object> params) => localizeFill(this, params);
  String plural(int value) => localizePlural(value, this, _t);
  String version(Object modifier) => localizeVersion(modifier, this, _t);
}
