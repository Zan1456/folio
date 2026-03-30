import 'package:i18n_extension/i18n_extension.dart';

extension AbsenceSubjectModalLocalization on String {
  static final _t = Translations.byLocale("hu-HU") +
      {
        "en-US": {
          "excused_state": "Excused",
          "pending_state": "Pending",
          "unexcused_state": "Unexcused",
          "lesson": "lesson",
        },
        "hu-HU": {
          "excused_state": "Igazolt",
          "pending_state": "Igazolandó",
          "unexcused_state": "Igazolatlan",
          "lesson": "óra",
        },
        "de-DE": {
          "excused_state": "Anerkannt",
          "pending_state": "Ausstehend",
          "unexcused_state": "Unentschuldigt",
          "lesson": "Stunde",
        },
      };

  String get i18n => localize(this, _t);
  String fill(List<Object> params) => localizeFill(this, params);
  String plural(int value) => localizePlural(value, this, _t);
  String version(Object modifier) => localizeVersion(modifier, this, _t);
}
