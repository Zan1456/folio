import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byLocale("hu-HU") +
      {
        "en-US": {
          "Messages": "Messages",
          "Inbox": "Inbox",
          "Sent": "Sent",
          "Trash": "Trash",
          "Draft": "Draft",
          "empty": "You have no messages.",
          "Send": "Send",
        },
        "hu-HU": {
          "Messages": "Üzenetek",
          "Inbox": "Beérkezett",
          "Sent": "Elküldött",
          "Trash": "Kuka",
          "Draft": "Piszkozat",
          "empty": "Nincsenek üzeneteid.",
          "Send": "Küldés",
        },
        "de-DE": {
          "Messages": "Nachrichten",
          "Inbox": "Posteingang",
          "Sent": "Gesendet",
          "Trash": "Müll",
          "Draft": "Entwurf",
          "empty": "Sie haben keine Nachrichten.",
          "Send": "Senden",
        },
      };

  String get i18n => localize(this, _t);
  String fill(List<Object> params) => localizeFill(this, params);
  String plural(int value) => localizePlural(value, this, _t);
  String version(Object modifier) => localizeVersion(modifier, this, _t);
}

