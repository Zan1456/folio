import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byLocale("hu-HU") +
      {
        "en-US": {
          "Room": "Room",
          "Description": "Description",
          "Lesson Number": "Lesson Number",
          "Group": "Group",
          "edit_lesson": "Edit Lesson",
          "l_desc": "Description...",
          "done": "Done",
          "cancel": "Cancel",
          "year_index": "Lesson Number",
        },
        "hu-HU": {
          "Room": "Terem",
          "Description": "Leírás",
          "Lesson Number": "Éves óraszám",
          "Group": "Csoport",
          "edit_lesson": "Óra szerkesztése",
          "l_desc": "Leírás...",
          "done": "Kész",
          "cancel": "Mégse",
          "year_index": "Éves óraszám",
        },
        "de-DE": {
          "Room": "Raum",
          "Description": "Bezeichnung",
          "Lesson Number": "Ordinalzahl",
          "Group": "Gruppe",
          "edit_lesson": "Lektion bearbeiten",
          "l_desc": "Beschreibung...",
          "done": "Erledigt",
          "cancel": "Abbrechen",
          "year_index": "Ordinalzahl",
        }
      };

  String get i18n => localize(this, _t);
  String fill(List<Object> params) => localizeFill(this, params);
  String plural(int value) => localizePlural(value, this, _t);
  String version(Object modifier) => localizeVersion(modifier, this, _t);
}

